
exception Exception
exception Exc_int of int
exception Exc_int_int of int * int

let () =
  Memgraph.Repr.(context (fun ctx ->
      Memgraph.Dot.print_list Format.std_formatter [
        "Exception", ctx.mk Exception;
        "Exc_int 0", ctx.mk (Exc_int 0);
        "Exc_int 123", ctx.mk (Exc_int 123);
        "Exc_int_int", ctx.mk (Exc_int_int (456,789));
      ]))

