(lang dune 2.7)

; Project info
(name memgraph)
(version 1.0)
(license MIT)
(source (github gbury/ocaml-memgraph))
(authors "Guillaume Bury <guillaume.bury@gmail.com>")
(maintainers "Guillaume Bury <guillaume.bury@gmail.com>")

; Project options
(formatting disabled)
(generate_opam_files true)
(implicit_transitive_deps false)

; Memgraph package
(package
  (name memgraph)
  (depends (ocaml (>= 4.05.0)))
  (synopsis "A small library to inspect memory representation of ocaml values")
  (description "Memgraph alows one to inspect an ocaml value and get a representation of its layout in memory, and helpers to dump such representation as dot files to easily print them as graphs")
)
