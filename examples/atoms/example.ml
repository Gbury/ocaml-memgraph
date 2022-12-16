
let e = [| |]
let f = [| |]
let arr = Array.make 0 0

let () =
  Memgraph.Repr.(context (fun ctx ->
      Memgraph.Dot.print_list Format.std_formatter [
        {|[\| \|]|}, ctx.mk e;
        {|[\| \|]|}, ctx.mk f;
        {|Array.make 0 0|}, ctx.mk arr;
      ]))

