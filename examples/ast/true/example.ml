
type location = {
  file : string;
  start_line : int;
  start_column : int;
  stop_line : int;
  stop_column : int;
}

type namespace =
  | Var
  | Type
  | Term

type id = {
  ns : namespace;
  name : string;
}

type builtin =
  | True | False
  | And | Or | Not

type binder =
  | Forall | Exists

type descr =
  | Symbol of id
  | Builtin of builtin
  | Colon of t * t
  | App of t * t list
  | Binder of binder * t list * t
  | Match of t * (t * t) list

and t = {
  term : descr;
  attr : t list;
  loc : location option;
}

let loc_file = "example.dummy"

let mk_loc l c n = {
  file = loc_file;
  start_line = l;
  start_column = c;
  stop_line = l;
  stop_column = c + n;
}

let mk ?loc term = { term; loc; attr = []; }

let true_ = mk ~loc:(mk_loc 1 1 1) (Builtin True)
let false_ = mk ~loc:(mk_loc 1 3 1) (Builtin False)
let and_ = mk ~loc:(mk_loc 1 2 1) (Builtin And)
let t = mk ~loc:(mk_loc 1 1 3) (App (and_, [true_; false_]))

let () =
  Memgraph.Dot.print_list Format.std_formatter (
    (Memgraph.Repr.context (fun ctx -> [
        "true", ctx.mk true_;
        "true_loc", ctx.mk (true_.loc);
        "true_desc", ctx.mk (true_.term);
      ]))
    )

