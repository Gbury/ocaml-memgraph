(lang dune 2.7)

; Project info
(name memgraph)
(version 1.0)
(license MIT)
(source (github gbury/ocaml-memgraph))
(documentation https://gbury.github.io/ocaml-memgraph/)
(authors "Guillaume Bury <guillaume.bury@gmail.com>"
         "Armaël Guéneau <armael.gueneau@ens-lyon.org>")
(maintainers "Guillaume Bury <guillaume.bury@gmail.com>"
             "Armaël Guéneau <armael.gueneau@ens-lyon.org>")

; Project options
(formatting disabled)
(generate_opam_files true)
(implicit_transitive_deps false)

; Memgraph package
(package
  (name memgraph)
  (depends (ocaml (>= 4.05.0)))
  (synopsis "A small library to inspect memory representation of ocaml values")
  (description "Memgraph allows one to inspect an ocaml value and get a representation of its layout in memory, and helpers to dump such representation as dot files to easily print them as graphs")
)

; Memgraph_kitty package
(package
  (name memgraph_kitty)
  (depends
     (ocaml (>= 4.05.0))
     (memgraph (= :version))
     (ppx_blob (and :build (>= 0.7.0)))
     (nanosvg (>= 0.1))
     (nanosvg_text (>= 0.1))
     (kittyimg (>= 0.1))
     (stb_truetype (>= 0.7))
     conf-graphviz)
  (synopsis "Display the representation of memory values in the Kitty terminal emulator")
  (description "Memgraph_kitty inspects ocaml values and displays their graphical representation using the graphics protocol of the kitty terminal emulator"))
