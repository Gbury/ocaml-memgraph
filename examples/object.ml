
let x = object(self)

  val foo = 5

  method f x =
    self#f (x - 1) * x

  method g y =
    foo + y

  end

let () =
  Repr.(context (fun ctx ->
      Dot.print_list Format.std_formatter [
        "object:foo+factorial", ctx.mk x;
      ]))
