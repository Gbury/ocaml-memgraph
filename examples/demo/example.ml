
let int = 13
let float = 42.
let int_list = [1;2;3]
let int_array = [| 1 ; 2 ; 3 |]
let float_array = [| 1.0; 2.0; 3.0 |]
let rec cycle = 1 :: 2 :: 3 :: cycle

let () =
  Memgraph.Repr.(context (fun ctx ->
      Memgraph.Dot.print_list Format.std_formatter [
        {|let rec l = 1 :: 2 :: 3 :: l|}, ctx.mk cycle;
        {|[\|1.0;2.0;3.0;4.0\|]|}, ctx.mk float_array;
        {|[\|1;2;3\|]|}, ctx.mk int_array;
        {|[1;2;3]|}, ctx.mk int_list;
        {|42.0|}, ctx.mk float;
        {|13|}, ctx.mk int;
      ]))

