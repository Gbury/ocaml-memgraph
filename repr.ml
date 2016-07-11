
type tag = int
type addr = int

type cell =
  | Abstract
  | Int of int
  | Double of float
  | String of string
  | Pointer of addr

and block = {
  addr : addr; (* unique int to preserve sharing *)
  tag : tag;
  fields : cell array;
}

type env = {
  graph : (int, block) Hashtbl.t;
  mutable assoc : (Obj.t * int) list;
}

let env = {
  graph = Hashtbl.create 42;
  assoc = [];
}

let pp_cell fmt = function
  | Abstract -> Format.fprintf fmt "abstract"
  | Int i -> Format.fprintf fmt "%d" i
  | Double f -> Format.fprintf fmt "%f" f
  | String s -> Format.fprintf fmt "%s" s
  | Pointer d -> Format.fprintf fmt "#%d" d

let pp_array fmt a =
  Array.iter (fun c -> Format.fprintf fmt "%a;@;" pp_cell c) a

let pp_block fmt b =
  Format.fprintf fmt "{%d}@;%a" b.tag pp_array b.fields

let follow b = Hashtbl.find env.graph b

let new_addr =
  let i = ref 0 in
  (fun () -> incr i; !i)

let mk_block addr tag fields = { addr; tag; fields; }

let rec mk_val addr v =
  let tag = Obj.tag v in
  let fields =
    if tag = Obj.double_tag then
      [| Double (Obj.obj v : float) |]
    else if tag = Obj.string_tag then
      [| String (Obj.obj v : string) |]
    else if tag = Obj.double_array_tag then
      (Array.init (Obj.size v) (fun i -> Double (Obj.double_field v i)))
    else if tag <= 245 || tag = 248 then
      (Array.init (Obj.size v) (fun i -> mk (Obj.field v i)))
    else
      [| Abstract |]
  in
  let b = mk_block addr tag fields in
  Hashtbl.add env.graph addr b

and mk t =
  try Pointer (List.assq t env.assoc)
  with Not_found ->
    if Obj.is_int t then
      Int (Obj.obj t : int)
    else begin
      let addr = new_addr () in
      env.assoc <- (t, addr) :: env.assoc;
      mk_val addr t;
      Pointer addr
    end

let repr v = mk (Obj.repr v)

