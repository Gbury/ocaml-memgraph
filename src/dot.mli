
(** Dot output

    This module provides some helper to print the memory representation of
    ocaml values as graphviz graphs. *)

(** {2 Settings} *)

type config
(** The [config] type gathers tweakable settings of the graphviz output. See the
   [config] function below for constructing values of type [config]. *)

val config :
  ?external_node_color : string option ->
  ?block_node_color : string option ->
  ?root_node_color : string option ->
  ?outline_color : string ->
  ?background_color : string option ->
  ?direction : [`Vertical | `Horizontal] ->
  unit ->
  config
(** Build a value of type [config], provided some of the following (all
    optional) settings. (For colors provided as a [string option], the [None]
    value corresponds to transparency.)

    - [external_node_color]: the fill color of nodes for out-of-heap pointers
      (default: [Some "grey"]);
    - [block_node_color]: the fill color of standard block nodes
      (default: [Some "lightblue"]);
    - [root_node_color]: the fill color of root notes
      (default: [Some "yellow"]);
    - [outline_color]: the color of the outlines of nodes, edges, and text
      (default: ["black"]);
    - [background_color]: the color of the background (default: [None]);
    - [direction]: whether to lay out successive nodes from top to bottow
      ([`Vertical]) or left to right ([`Horizontal]) (default: [`Vertical]).
*)

(** {2 Dot Printing functions} *)

val print_list : config -> Format.formatter -> (string * [`Direct] Repr.cell) list -> unit
(** Print a list of reprs on the given formatter. *)

val to_file : config -> string -> (string * [`Direct] Repr.cell) list -> unit
(** Print a list of reprs in the given file (the file must not exist and will be
   created by this function) *)
