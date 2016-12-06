
(* Prelude *)

let x = 5.
let l = lazy (x +. 42.)

let l_repr = Repr.repr l
let l_val = Repr.repr (Lazy.force l)
let l_forced = Repr.repr l

;;
(* Printing *)
Repr.(context (fun ctx ->
    Dot.print_list Format.std_formatter [
      "lazy: 5 + 42", l_repr;
      "lazy_forced", l_val;
      "lazy_after_forced", l_forced;
    ]))

