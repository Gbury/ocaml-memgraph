
type foo = {
  a : int;
  b : float;
  c : int;
  d : int;
}

type bar = {
  e : float;
  f : float;
  g : float;
}

type foobar = {
  h : int;
  foo : foo;
  bar : bar;
  i : float;
}

let foo = { a = 1; b = 42.; c = 2; d = 3; }
let bar = { e = 5.; f = 7.; g = 8.; }
let foobar = { h = 0; foo; bar; i = 9. }

let () =
  Repr.(context (fun ctx ->
      Dot.print_list Format.std_formatter [
        "foo = \{ a = 1; b = 42.; c = 2; d = 3; \}", ctx.mk foo;
        "bar = \{ e = 5.; f = 7.; g = 8.; \}", ctx.mk bar;
        "\{ h = 0; foo; bar; i = 9.; \}", ctx.mk foobar
      ]))

