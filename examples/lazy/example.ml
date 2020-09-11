
(* Prelude *)

let x = 5.
let l = lazy (x +. 42.)

let l_repr = Memgraph.Repr.repr l
let l_val = Memgraph.Repr.repr (Lazy.force l)
let l_forced = Memgraph.Repr.repr l

;;
(* Printing *)
Memgraph.Repr.(context (fun _ ->
    Memgraph.Dot.print_list Format.std_formatter [
      "lazy: 5 + 42", l_repr;
      "lazy_forced", l_val;
      "lazy_after_forced", l_forced;
    ]))

