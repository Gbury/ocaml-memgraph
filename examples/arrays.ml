

let int_array = [| 4 ; 5 ; 6 |]
let int_matrix = Array.make_matrix 3 5 42
let int_array_array = Array.make 3 (Array.make 5 42)

let int_float_array = [| (5,8.0); (42, 1.0); (0, 1.5) |]

let float_array = [| 1.0; 2.0; 3.0; 4.0 |]

let () =
  Repr.(context (fun ctx ->
      Dot.print_list Format.std_formatter [
        "[\|4;5;6\|]", ctx.mk int_array;
        "[\|1.0;2.0;3.0;4.0\|]", ctx.mk float_array;
        "[\| (5,8.0); (42, 1.0); (0, 1.5) \|]", ctx.mk int_float_array;
        "Array.make_matrix 3 5 42", ctx.mk int_matrix;
        "Array.make 3 (Array.make 5 42)", ctx.mk int_array_array;
      ]))

