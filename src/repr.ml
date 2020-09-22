
(* This file is free software, part of memgraph. See file "LICENSE" for more information *)

(* Inspecting ocaml values

   The implementation of this module should be safe, however it is
   very easy to make things become unsafe and crash or worse when
   using the {Obj} module, and particularly when reading fields
   like this module does (we're somewhat less unsafe because we
   only read info in this module, and do not modify anything, but
   still, it is delicate code).

   As far as I know, the current code should work across al versions
   of ocaml, whether it be native or bytecode. Note however that the
   closure representation differs from bytecode to native, so you
   may obtain different results depending on how you run this code.


   WARNING: if ever some more semantic information wanted to be
            extracted from ocaml values, great care muist be taken
            to consider the changes that occurred in the
            representation of ocaml values. Note: such additions
            could be made to an additional module, rather than in
            this code, potentially by adding some hooks/unsafe
            functions in this module to allow an external module
            to add this information.

  As far as I know, these changes are:

  * Closure representation and env vars (PR#9619)
    Starting from ocaml 4.12, sets of closures now record
    the field number of the start of their environment
    using the same field used for arity. The arity field now goes from
    `arity (wordsize - 1 bit) . 1`
    to
    `arity (8 bits) . start-of-environment (wordsize - 9 bits) . 1`
    Note that the start_of_environment is the field number (reminder:
    field number start at 0), *relative* to the closure (and not the
    set of closures, nor the arity field itself, but the closure
    header (e.g. the code_ptr has offset 0, the arity field has
    offset 1 in that numerotation)).
    This means different things for the native and bytecode backends:
    - in native mode, the arity field simply changes
    - in bytecode, the arity field was not present, and is now added to
      the representation of all closures.
    Hence, if there ever was a change to add some kind of semantic info
    in order to extract the arity and start-of-env info from such fields,
    conditional compilation *MUST* be used to avoid crashing when using
    bytecode with ocaml < 4.12

*)

(** Type definitions *)

type tag = int
(* Ocaml tags *)

type addr = int
(* Abstract addresses, used for sharing *)

type block = {
  addr : addr; (* unique int to preserve sharing *)
  tag  : tag;  (* block tag *)
  data : data; (* block contents *)
}

and data =
  | Abstract
  | Block of [ `Block ] cell
  | Fields of [ `Inline ] cell array (**)

and _ cell =
  | Int      : int          -> [< `Inline | `Direct ] cell  (* Integers *)
  | Pointer  : addr         -> [< `Inline | `Direct ] cell  (* Pointers to some block *)
  | External : Nativeint.t  -> [< `Inline ] cell            (* Out of heap pointer *)
  | String   : string       -> [< `Block ] cell             (* String *)
  | Double   : float        -> [< `Block | `Inline ] cell   (* A float *)
  | Infix    :                 [ `Inline ] cell             (* An infix header (used in closures) *)

type pblock = {
  block   : block;  (* The block being pointed at *)
  offset  : int;    (* The offset in the block (used in mutually rec closures) *)
}
(* This represents what is pointed at by a pointer. *)


type env = {
  graph : (addr, pblock) Hashtbl.t;
}
(* Environment for keeping track of values we have already seen.
   It is a hashtabl from addresses to blocks. *)

type assoc = (Obj.t * addr) list
(* The type for local environments. These are used to keep track of the
   translated values, and accurately represent sharing. *)

let env = {
  graph = Hashtbl.create 42;
}
(* The global environment used to keep track of the values we have
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
  if tag = Obj.infix_tag then
    (* Infix closures are special pointers that actually
       point inside a big closure block, and
       their size is actually an offset rather than a nnumber of blocks *)
    let offset = Obj.size v in
    (* Format.eprintf "Infix, offset: %d@." offset; *)
    (* offsets/addresses are in bytes, hence the word_size /8 mutliplication  *)
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
      if tag = Obj.double_tag then
        (* floats have a special tag *)
        let f : float = Obj.obj v in
        Block (Double f), assoc
      else if tag = Obj.string_tag then
        (* Strings store more than one char per word, so again, need to special case *)
        let s : string = Obj.obj v in
        Block (String s), assoc
      else if tag = Obj.double_array_tag then
        (* Float arrays must use special access functions *)
        let a = Array.init (Obj.size v)
            (fun i -> Double (Obj.double_field v i))
        in
        Fields a, assoc
      else if tag < Obj.no_scan_tag then begin
        (* General case, we parse an array of fields. *)
        let tmp = ref assoc in
        (* Format.eprintf "block size (%d): %d@." tag (Obj.size v); *)
        let a = Array.init (Obj.size v) (fun i ->
            let assoc', v = mk_inline !tmp (Obj.field v i) in
            tmp := assoc';
            v
          ) in
        Fields a, !tmp
      end else
        (* If we do not fit in the previous cases, the block's contents are unknown. *)
        Abstract, assoc
    in
    let block = mk_block addr tag data in
    Hashtbl.add env.graph addr { block; offset = 0; };
    (v, addr) :: assoc
  end

(** Wrapper for inline values. *)
and mk_inline: assoc -> Obj.t -> assoc * [ `Inline ] cell
  = fun assoc t ->
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


