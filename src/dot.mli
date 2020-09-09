
(** Dot output

    This module provides some helper to print the memory representation of
    ocaml values as graphviz graphs. *)

(** {2 Dot Printing functions} *)

val print_list :
  Format.formatter ->
  (string * [`Direct] Repr.cell) list -> unit
(** Print a list of reprs on the given formatter. *)

val to_file :
  string ->
  (string * [`Direct] Repr.cell) list -> unit
(** Print a list of reprs in the given file (the file must not exist and
    will be created by this function) *)

