
type t1 = {
  a : int;
  b : float;
}

type t2 = {
  c : float;
  d : float;
}

type t3 = {
  foo : t1;
  bar : t2
}

let foo = { a = 1; b = 42.; }
let bar = { c = 5.; d = 7.; }
let foobar = { foo; bar; }

let () =
  Repr.(context (fun ctx ->
      Dot.print_list Format.std_formatter [
        "foo = \{ a = 1; b = 42.; \}", ctx.mk foo;
        "bar = \{ c = 5.; b = 7. \}", ctx.mk bar;
        "\{ foo; bar; \}", ctx.mk foobar
      ]))

