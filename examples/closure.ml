
let f x = x + 1

let g x y z = x+y+z
let g1 = g 5
let g2 = g 7
let g3 = g1 42

let () =
  Repr.(context (fun ctx ->
      Dot.print_list Format.std_formatter [
        "f x = x + 1", ctx.mk f;
        "List.map", ctx.mk List.map;
        "List.map f", ctx.mk (List.map f);
        "g x y z = x + y + z", ctx.mk g;
        "g1 = g 5", ctx.mk g1;
        "g2 = g 7", ctx.mk g2;
        "g3 = g1 42", ctx.mk g3;
      ]))

