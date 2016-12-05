
(** Type definitions *)

type tag = int
(** Ocaml tags *)

type addr = int
(** Abstract addresses, used for sharing *)

type block = {
  addr : addr; (* unique int to preserve sharing *)
  tag  : tag;
  data : data;
}
(** Represent OCaml blocks.
    - tag is the ocaml tag in the block header.
    - data is a high-level representation of the fields of the block.
    - addr is additional information used to keep track of sharing between values.
*)

and data =
  | Block of [ `Block ] cell
  | Fields of [ `Inline ] cell array
(** To have a high-level representation of a block's fields,
    we distinguish two cases: either the block contain a single big value
    (typically a string and/or a float), or it contains an array of values. *)

and _ cell =
  | Abstract :           [< `Inline ] cell            (** Value not yet handled *)
  | Int      : int    -> [< `Inline | `Direct ] cell  (** Integers *)
  | Pointer  : addr   -> [< `Inline | `Direct ] cell  (** Pointers to some block *)
  | String   : string -> [< `Block ] cell             (** String *)
  | Double   : float  -> [< `Block | `Inline ] cell   (** A float *)
(** The actual type of memory cells containing real values.
    There are actually three type of cells:
    - [`Direct] cells are values that can be found in ocaml variables
    - [`Inline] cells are values that can be found in a block's field array
    - [`Block]  cells are "big" values that take a whole block

    Obviously, some constructors can build more than one type of cells.
*)


(* Environment for keeping track of values we have already seen. *)

type env = {
  graph : (int, block) Hashtbl.t;
}

let env = {
  graph = Hashtbl.create 42;
}

(* Some helper functions *)

(* Follow a pointer, i.e. "dereference" it *)
let follow b =
  Hashtbl.find env.graph b

(* Function to iter over a block and all its descendants..
   We use a hashtbl to ensure we don't loop on cyclic values *)
let walk f init =
  let h = Hashtbl.create 42 in
  let s = Stack.create () in
  let () = Stack.push init.addr s in
  try
    while true do
      let x = Stack.pop s in
      if Hashtbl.mem h x then ()
      else begin
        Hashtbl.add h x true;
        let b = follow x in
        let () = f b in
        match b.data with
        | Block _ -> ()
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


(* Creating new blocks *)
let new_addr =
  let i = ref 0 in
  (fun () -> incr i; !i)

let mk_block addr tag data = { addr; tag; data; }


(* Converting Obj.t into blocks *)

let rec mk_val assoc addr v =
  let tag = Obj.tag v in
  let data, assoc =
    if tag = Obj.double_tag then
      let f : float = Obj.obj v in
      Block (Double f), assoc
    else if tag = Obj.string_tag then
      let s : string = Obj.obj v in
      Block (String s), assoc
    else if tag = Obj.double_array_tag then
      let a = Array.init (Obj.size v)
          (fun i -> Double (Obj.double_field v i))
      in
      Fields a, assoc
    else if tag < Obj.no_scan_tag then begin
      let tmp = ref assoc in
      let a = Array.init (Obj.size v) (fun i ->
          let assoc', v = mk_aux !tmp (Obj.field v i) in
          tmp := assoc';
          v
        ) in
      Fields a, !tmp
    end else
      Fields [| Abstract |], assoc
  in
  let b = mk_block addr tag data in
  Hashtbl.add env.graph addr b;
  (v, b.addr) :: assoc

and mk_aux: 'a.
  (Obj.t * addr) list -> Obj.t ->
  (Obj.t * addr) list * ([< `Inline | `Direct ] as 'a) cell
  = fun assoc t ->
  if Obj.is_int t then
    let res : [< `Inline | `Direct ] cell = Int (Obj.obj t : int) in
    assoc, res
  else begin
    try
      let res : [< `Inline | `Direct ] cell = Pointer (List.assq t assoc) in
      assoc, res
    with Not_found ->
      let addr = new_addr () in
      let assoc' = mk_val ((t, addr) :: assoc) addr t in
      let res : [< `Inline | `Direct ] cell = Pointer addr in
      assoc', res
  end

let repr x : [ `Direct ] cell =
  snd (mk_aux [] (Obj.repr x))


(* Share a context between calls to repr... *)
type context = { mk : 'a. 'a -> [ `Direct ] cell }

let context f =
  let assoc = ref [] in
  let context = {
    mk = function x ->
      let l, res = mk_aux !assoc (Obj.repr x) in
      assoc := l;
      res;
  } in
  f context


