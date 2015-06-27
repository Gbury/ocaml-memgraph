
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

let follow b = Hashtbl.find env.graph b

let new_addr =
  let i = ref 0 in
  (fun () -> incr i; !i)

let mk_block addr tag fields = { addr; tag; fields; }

let rec mk_val addr v =
  let tag = Obj.tag v in
  let fields =
    if tag = Obj.double_tag then
      Some [| Double (Obj.obj v : float) |]
    else if tag = Obj.string_tag then
      Some [| String (Obj.obj v : string) |]
    else if tag = Obj.double_array_tag then
      Some (Array.init (Obj.size v) (fun i -> Double (Obj.double_field v i)))
    else if tag <= 240 then
      Some (Array.init (Obj.size v) (fun i -> mk (Obj.field v i)))
    else
      None
  in
  match fields with
  | Some a ->
    let b = mk_block addr tag a in
    Hashtbl.add env.graph addr b;
    true
  | None -> false

and mk t =
  try Pointer (List.assq t env.assoc)
  with Not_found ->
    if Obj.is_int t then
      Int (Obj.obj t : int)
    else begin
      let addr = new_addr () in
      env.assoc <- (t, addr) :: env.assoc;
      if mk_val addr t then
        Pointer addr
      else
        Abstract
    end

let repr v = mk (Obj.repr v)

