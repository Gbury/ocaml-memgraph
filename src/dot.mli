

val print_list :
  Format.formatter ->
  (string * [`Direct] Repr.cell) list -> unit

val to_file :
  string ->
  (string * [`Direct] Repr.cell) list -> unit

