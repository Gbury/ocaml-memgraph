
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


(** Environment for keeping track of values we have already seen. *)

type env = {
  graph : (int, block) Hashtbl.t;
}

let env = {
  graph = Hashtbl.create 42;
}

(** Some helper functions *)

let follow b =
  Hashtbl.find env.graph b

let walk f init =
  let s = Stack.create () in
  let () = Stack.push init s in
  try
    while true do
      let x = Stack.pop s in
      let () = f x in
      match x.data with
      | Block _ -> ()
      | Fields a ->
        Array.iter (function
            | Pointer b -> Stack.push (follow b) s
            | _ -> ()) a
    done
  with Stack.Empty -> ()

(** Creating new blocks *)

let new_addr =
  let i = ref 0 in
  (fun () -> incr i; !i)

let mk_block addr tag data = { addr; tag; data; }


(** Converting Obj.t into blocks *)

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
    else if tag <= 245 ||
            tag = Obj.object_tag ||
            tag = Obj.forward_tag then
      let tmp = ref assoc in
      let a = Array.init (Obj.size v) (fun i ->
          let assoc', v = mk_aux !tmp (Obj.field v i) in
          tmp := assoc';
          (v :> [ `Inline ] cell)
        ) in
      Fields a, !tmp
    else
      Fields [| Abstract |], assoc
  in
  let b = mk_block addr tag data in
  Hashtbl.add env.graph addr b;
  (v, b.addr) :: assoc

(* Should really have a polymorphic return type 'a = [< `Inline | `Direct ] cell,
   but because of the call above, has only [ `Inline ] cell type... *)
and mk_aux:
  (Obj.t * addr) list -> Obj.t ->
  (Obj.t * addr) list * [< `Inline | `Direct ] cell
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

