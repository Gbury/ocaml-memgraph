
let test () =
  let n = Random.int 10 in

  let rec f x y = n + n + y + g x
  and g y = f y (y + 1) in

  f, g

let () =
  let f, g = test () in
  Memgraph.Repr.(context (fun ctx ->
    Memgraph.Dot.print_list Format.std_formatter [
      "f", ctx.mk f;
      "g", ctx.mk g;
    ]))

