
(* Prelude *)
module M = Map.Make(struct type t = int let compare = Pervasives.compare end)

let m1 = M.(add 1 "a" (add 3 "c" (add 2 "b" empty)))
let m2 = M.remove 2 m1

let rec l = 1 :: 2 :: 3 :: l

;;
(* Printing *)
Dot.to_file "temp.gv" [
  "int_list", Repr.repr [1;2;3];
  "float_list", Repr.repr [1.;2.;3.];
  "circular_list", Repr.repr l;
  "float_tuple", Repr.repr (9., 42.);
  "float_array", Repr.repr [| 4.; 5.; 6.; 7.; 8.; 9. |];
  "map1", Repr.repr m1;
  "map2",Repr.repr m2;
]


