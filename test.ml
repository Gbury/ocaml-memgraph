
(* Prelude *)
module H = Hashtbl.Make(struct type t = int let hash i = i let equal = (=) end)

let h = H.create 2
let () = H.add h 1 2
let () = H.add h 2 3
let () = H.add h 3 5
let () = H.add h 17 42

;;
(* Printing *)
Dot.to_file "temp.gv" [
  "int_list", Repr.repr [1;2;3];
  "float_list", Repr.repr [1.;2.;3.];
  "float_tuple", Repr.repr [| 4.; 5. |];
  "hashtbl", Repr.repr h;
]


