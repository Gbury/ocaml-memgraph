
(** Type definitions *)

type tag = int
(** Ocaml tags *)

type addr = int
(** Abstract addresses, used for sharing *)

type block = {
  addr : addr; (** unique int to preserve sharing *)
  tag  : tag;  (** Block tag *)
  data : data; (** Block contents *)
}
(** Represent OCaml blocks.
    - tag is the ocaml tag in the block header.
    - data is a high-level representation of the fields of the block.
    - addr is additional information used to keep track of sharing between values.
*)

and data =
  | Abstract
  | Block of [ `Block ] cell
  | Fields of [ `Inline ] cell array
(** To have a high-level representation of a block's fields,
    we distinguish two cases: either the block contain a single big value
    (typically a string and/or a float), or it contains an array of values. *)

and _ cell =
  | Int      : int          -> [< `Inline | `Direct ] cell  (** Integers *)
  | Pointer  : addr         -> [< `Inline | `Direct ] cell  (** Pointers to some block *)
  | External : Nativeint.t  -> [< `Inline ] cell            (** Out of heap pointer *)
  | String   : string       -> [< `Block ] cell             (** String *)
  | Double   : float        -> [< `Block | `Inline ] cell   (** A float *)
  | Infix    :                 [ `Inline ] cell             (** An infix header (used in closures) *)
(** The actual type of memory cells containing real values.
    There are actually three type of cells:
    - [`Direct] cells are values that can be found in ocaml variables
    - [`Inline] cells are values that can be found in a block's field array
    - [`Block]  cells are "big" values that take a whole block

    Obviously, some constructors can build more than one type of cells.
*)

type pblock = {
  block   : block;  (** The block being pointed at *)
  offset  : int;    (** The offset in the block (used in mutually rec closures) *)
}
(** This represents what is pointed at by a pointer. *)


type env = {
  graph : (addr, pblock) Hashtbl.t;
}
(** Environment for keeping track of values we have already seen.
    It is a hashtabl from addresses to blocks. *)

type assoc = (Obj.t * addr) list
(** The type for local environments. These are used to keep track of the
    translated values, and accurately represent sharing. *)

let env = {
  graph = Hashtbl.create 42;
}
(** The global environment used to keep trakc of the values we have
    translated. *)


(** Follow a pointer, i.e. "dereference" it *)
let follow b =
  Hashtbl.find env.graph b

(** Function to iter over a block and all its descendants..
    We use a hashtbl to ensure we don't loop on cyclic values *)
let walk f init =
  let h = Hashtbl.create 42 in
  let s = Stack.create () in
  let () = Stack.push init.block.addr s in
  try
    while true do
      let x = Stack.pop s in
      if Hashtbl.mem h x then ()
      else begin
        Hashtbl.add h x true;
        let b = follow x in
        let () = f b in
        match b.block.data with
        | Abstract | Block _ -> ()
        | Fields a -> Array.iter (
            function
            | Pointer addr ->
              if not (Hashtbl.mem h addr) then
                Stack.push addr s
            | _ -> ()
          ) a
      end
    done
  with Stack.Empty -> ()


(** Creating new blocks.
    We use a ref to generate fresh addresses for blocks. *)
let new_addr =
  let i = ref 0 in
  (fun () -> incr i; !i)

let mk_block addr tag data =
  { addr; tag; data; }


(** Converting Obj.t into blocks.
    Some important points:
    - we need to keep track of the values that we have already translated,
      in order to not loop on cyclic values, and to faithfully represent
      sharing. This is donne using an association list.
    - Some tags must be singled out (see comments inside function).
*)
let rec mk_val assoc addr v =
  let tag = Obj.tag v in
  (* Infix closures are special pointers that actually
     point inside a big closure block, and
     their size is actually an offset rather than a nnumber of blocks *)
  if tag = Obj.infix_tag then
    let offset = Obj.size v in
    Format.eprintf "Infix, offset: %d@." offset;
    (** offsets/addresses are in bytes, hence the word_size /8 mutliplication  *)
    let super = Obj.add_offset v Int32.(neg (of_int (offset * Sys.word_size / 8))) in
    match mk_direct assoc super with
    | assoc', Pointer addr' ->
      let b = follow addr' in
      assert (b.offset = 0);
      (* set the infix block header in the super block *)
      begin match b.block.data with
        | Fields a -> a.(offset - 1) <- Infix
        | _ -> assert false
      end;
      Hashtbl.add env.graph addr { block = b.block; offset; };
      (v, addr) :: assoc'
    | _, Int _ -> assert false
  else begin
    let data, assoc =
      (* floats have a special tag *)
      if tag = Obj.double_tag then
        let f : float = Obj.obj v in
        Block (Double f), assoc
        (* Strings store more than one char per word, so again, need to special case *)
      else if tag = Obj.string_tag then
        let s : string = Obj.obj v in
        Block (String s), assoc
        (* float arrays must use special access functions *)
      else if tag = Obj.double_array_tag then
        let a = Array.init (Obj.size v)
            (fun i -> Double (Obj.double_field v i))
        in
        Fields a, assoc
        (* General case, we parse an array of fields. *)
      else if tag < Obj.no_scan_tag then begin
        let tmp = ref assoc in
        Format.eprintf "block size (%d): %d@." tag (Obj.size v);
        let a = Array.init (Obj.size v) (fun i ->
            let assoc', v = mk_inline !tmp (Obj.field v i) in
            tmp := assoc';
            v
          ) in
        Fields a, !tmp
        (* If we do not fit in the previous cases, the block's contents are unknown. *)
      end else
        Abstract, assoc
    in
    let block = mk_block addr tag data in
    Hashtbl.add env.graph addr { block; offset = 0; };
    (v, addr) :: assoc
  end

(** Wrapper for inline values. *)
and mk_inline: assoc -> Obj.t -> assoc * [ `Inline ] cell = fun assoc t ->
  if Obj.is_int t then
    assoc, Int (Obj.obj t : int)
  else if Obj.tag t = Obj.out_of_heap_tag then
    let x : int = Obj.magic t in
    let y = Nativeint.(mul (of_int 2) (of_int x)) in
    assoc, External y
  else begin
    try
      assoc, Pointer (List.assq t assoc)
    with Not_found ->
      let addr = new_addr () in
      let assoc' = mk_val ((t, addr) :: assoc) addr t in
      assoc', Pointer addr
  end

(** Wrapper for direct values *)
and mk_direct: assoc -> Obj.t -> assoc * [ `Direct ] cell
  = fun assoc t ->
    if Obj.is_int t then
      assoc, Int (Obj.obj t : int)
    else begin
      try
        assoc, Pointer (List.assq t assoc)
      with Not_found ->
        let addr = new_addr () in
        let assoc' = mk_val ((t, addr) :: assoc) addr t in
        assoc', Pointer addr
    end

(** Exported function to translate a single value. *)
let repr x : [ `Direct ] cell =
  snd (mk_direct [] (Obj.repr x))

(** Exported function to translate mutliple values using the same context,
    in order to preserve the sharing of values across calls to "mk". *)
type context = { mk : 'a. 'a -> [ `Direct ] cell }

let context f =
  let assoc = ref [] in
  let context = {
    mk = function x ->
      let l, res = mk_direct !assoc (Obj.repr x) in
      assoc := l;
      res;
  } in
  f context



(* FOllow out_of_heap pointer !! yeehaw ! *)

(* caml_bytes_get64u :lit un entier 64 bits depuis un bytes (u = unsafe)
                      bytes -> int -> Int64.t
                      version 32u pour 32 bits
      -> caster vers nativeint,

  -> get the tag even for out_of_heap *)

