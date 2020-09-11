
let x = object(self)

  val foo = 5

  method f x =
    self#f (x - 1) * x

  method g y =
    foo + y

  end

let () =
  Memgraph.Repr.(context (fun ctx ->
      Memgraph.Dot.print_list Format.std_formatter [
        "object", ctx.mk x;
      ]))
