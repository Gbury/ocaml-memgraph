
let unit = ()
let int = 13
let bool = true
let char = 'a'

let () =
  Memgraph.Repr.(context (fun ctx ->
      Memgraph.Dot.print_list Format.std_formatter [
        {|unit|}, ctx.mk unit;
        {|char|}, ctx.mk char;
        {|true|}, ctx.mk bool;
        {|13|}, ctx.mk int;
      ]))

