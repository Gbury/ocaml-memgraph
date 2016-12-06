
exception Exception
exception Exc_int of int
exception Exc_int_int of int * int

let () =
  Repr.(context (fun ctx ->
      Dot.print_list Format.std_formatter [
        "Exception", Repr.repr Exception;
        "Exc_int 0", Repr.repr (Exc_int 0);
        "Exc_int 123", Repr.repr (Exc_int 123);
        "Exc_int_int", Repr.repr (Exc_int_int (456,789));
      ]))

