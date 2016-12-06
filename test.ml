
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

let x = 5.
let l = lazy (x +. 42.)

let l_repr = Repr.repr l
let l_val = Repr.repr (Lazy.force l)
let l_forced = Repr.repr l

let l = [5; 6]
let l1 = 2 :: l
let l2 = 3 :: l

let f x = x + 1

let g x y z = x+y+z
let g1 = g 5
let g2 = g1 42
let g3 = g 7

;;
(* Printing *)
Repr.(context (fun ctx ->
    Dot.to_file "temp.gv" [
      "l", ctx.mk l;
      "f", ctx.mk f;
      "map", ctx.mk List.map;
      "map_f", ctx.mk (List.map f);
      "g x y z", ctx.mk g;
      "g1 = g 5", ctx.mk g1;
      "g2 = g1 42", ctx.mk g2;
      "g3 = g 7", ctx.mk g3;
  (*
  "lazy: 5 + 42", l_repr;
  "lazy_forced", l_val;
  "lazy_after_forced", l_forced;
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
    ]))

