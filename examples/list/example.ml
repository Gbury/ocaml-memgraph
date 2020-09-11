
let empty = []
let int_list = [ 1 ; 2 ; 3 ]
let float_list = [ 1. ; 2. ; 3. ]

let l = [42]
let l1 = 1::2::l
let l2 = 3::4::l

let rec cyclic = 1 :: 2 :: 3 :: cyclic

let () =
  Memgraph.Repr.(context (fun ctx ->
      Memgraph.Dot.print_list Format.std_formatter [
        "[]", ctx.mk empty;
        "[1;2;3]", ctx.mk int_list;
        "[1.;2.;3.]", ctx.mk float_list;
        "l = [42]", ctx.mk l;
        "1 :: 2 :: l", ctx.mk l1;
        "3 :: 4 :: l", ctx.mk l2;
        "cyclic", ctx.mk cyclic;
      ]))
