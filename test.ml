
(* Prelude *)
let rec l = 1 :: 2 :: 3 :: l

type t =
  | A of int * int
  | B of (int * int)
  | C of float

exception Test1
exception Test2 of int
exception Test3 of int
exception Test4 of int * int

;;
(* Printing *)
Dot.to_file "temp.gv" [
  "unit", Repr.repr();
  "int", Repr.repr 0;
  "float_list", Repr.repr [1.;2.;3.];
  "circular_list", Repr.repr l;
  (*
  "float_array", Repr.repr [| 4.; 5.; 6.; 7.; 8.; 9. |];
  "A 1,2", Repr.repr (A (1,2));
  "B(3,4)", Repr.repr (B (3,4));
  "C 0.0", Repr.repr (C (0.0));
  *)
  "exc_test1", Repr.repr Test1;
  "exc_test2", Repr.repr (Test2 0);
  "exc_test3", Repr.repr (Test3 123);
  "exc_test3 (bis)", Repr.repr (Test3 321);
  "exc_test4", Repr.repr (Test4 (456,789));
]


