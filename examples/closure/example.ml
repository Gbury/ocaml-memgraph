
let f x = x + 1

let g x y z = x+y+z
let g1 = g 5
let g2 = g 7
let g3 = g1 42

let env =
  let h = Hashtbl.create 5 in
  let h' = Hashtbl.create 13 in
  (fun (y : int) (z: int) -> Hashtbl.find h y + Hashtbl.find h' z)

let rec h x1 x2 x3 = i x1 x2 x3
and     i y1 y2 y3 = j y1 y2 y3
and     j z1 z2 z3 = h z1 z2 z3

let () =
  Memgraph.Repr.(context (fun ctx ->
      Memgraph.Dot.print_list Format.std_formatter [
        "f x = x + 1", ctx.mk f;
        "List.map", ctx.mk List.map;
        "List.map f", ctx.mk (List.map f);
        "g x y z = x + y + z", ctx.mk g;
        "g1 = g 5", ctx.mk g1;
        "g2 = g 7", ctx.mk g2;
        "g3 = g1 42", ctx.mk g3;
        "let rec h x = i x", ctx.mk h;
        "let rec i y = j y", ctx.mk i;
        "let rec j z = h z", ctx.mk j;
      ]))

