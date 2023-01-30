![Build](https://github.com/gbury/ocaml-memgraph/workflows/build/badge.svg)

# Memgraph

A small library to output memory graph for ocaml values. Memgraph can be used
to generate graphs that represent the memory layout of any valid ocaml value.
Memgraph can produce `.dot` files that can then be processed using the
[graphviz](https://graphviz.org/) suite of tools to generate images of the
memory graph of ocaml values.

You can look at the [examples folder](https://github.com/Gbury/ocaml-memgraph/tree/master/examples)
to see how to use memgraph.

![example](https://github.com/Gbury/ocaml-memgraph/blob/master/examples/demo/example.svg)

# Memgraph & Kitty

For users of the [kitty terminal emulator](https://sw.kovidgoyal.net/kitty/), you can
use the `Memgraph_kitty` package and library to show the memory graph directly in a
toplevel session (using `ocaml` or `utop` for instance).

![kitty](https://github.com/Gbury/ocaml-memgraph/blob/master/examples/kitty.png)

WARNING: using this module in a terminal other thank kitty may lead to weird behaviour,
such as filling your screen with weird characters.

