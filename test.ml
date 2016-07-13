
(* Prelude *)
let rec l = 1 :: 2 :: 3 :: l

let arr = [| 1.0; 2.0; 3.0; 4.0 |]

type t =
  | A of int * int
  | B of (int * int)
  | C of float

exception Exception
exception Exc_int of int
exception Exc_int_int of int * int

let l = lazy (1 + 1)

let l_repr = Repr.repr l
let l_val = Repr.repr (Lazy.force l)
let l_forced = Repr.repr l

;;
(* Printing *)
Dot.to_file "temp.gv" [
  "lazy_2", l_repr;
  "lazy_val", l_val;
  "lazy_forced", l_forced;
  (*
  "unit", Repr.repr();
  "int", Repr.repr 0;
  "float_list", Repr.repr [1.;2.;3.];
  "circular_list", Repr.repr l;
  "float_array", Repr.repr arr;
  "A 1,2", Repr.repr (A (1,2));
  "`A 1,2", Repr.repr (`A (1,2));
  "B(3,4)", Repr.repr (B (3,4));
  "`B(3,4)", Repr.repr (`B (3,4));
  "C 0.0", Repr.repr (C (0.0));
  "`C 0.0", Repr.repr (`C (0.0));
  "Exception", Repr.repr Exception;
  "Exc_int 0", Repr.repr (Exc_int 0);
  "Exc_int 123", Repr.repr (Exc_int 123);
  "Exc_int_int", Repr.repr (Exc_int_int (456,789));
  *)
]


