
type t1 =
  | A of int * int
  | B of (int * int)
  | C of float
  | D
  | E
  | F of t1

let a = A (1, 2)
let b = B (3, 4)
let c = C 42.
let d = D
let e = E
let f = F a

let g = `G
let h = `H 5
let i = `I d
let j = `J (b, c)

let () =
  Memgraph.Repr.(context (fun ctx ->
    Memgraph.Dot.print_list Format.std_formatter [
      "a = A (1,2)", ctx.mk a;
      "b = B ((3,4))", ctx.mk b;
      "c = C 42.0", ctx.mk c;
      "d = D", ctx.mk d;
      "e = E", ctx.mk e;
      "f = F a", ctx.mk f;
      "g = `G", ctx.mk g;
      "h = `H 5", ctx.mk h;
      "i = `I d", ctx.mk i;
      "j = `J (b, c)", ctx.mk j;
    ]))

