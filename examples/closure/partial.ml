
let test () =
  let f x y z = x + y + z in
  f

let test2 () =
  let f x y z = x + y + z in
  let g = f 11 in
  f, g

let () =
  let _f1 = test () in
  let f2, _g2 = test2 () in
  Memgraph.Repr.(context (fun ctx ->
    Memgraph.Dot.print_list Format.std_formatter [
      (* "f1", ctx.mk f1; *)
      (* "f1 18", ctx.mk (f1 18); *)
      "f2", ctx.mk f2;
      (* "g2", ctx.mk g2; *)
      "f2 18", ctx.mk (f2 18);
    ]))
