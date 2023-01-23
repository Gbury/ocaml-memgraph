(** Display values graphically in the Kitty terminal emulator.

    This module provides functions to display the memory representation of OCaml
    values as {i images} in the terminal, by using the {{:
    https://sw.kovidgoyal.net/kitty/graphics-protocol}terminal graphics
    protocol} of the Kitty terminal emulator. The functions below thus assume
    that the program is running in Kitty (or any terminal emulator implementing
    the terminal graphics protocol). They can be called either from the toplevel
    loop or a compiled OCaml program.

    Usage:

    [show l] displays the memory representation of a list of values of the same
    type, labeled by names.

    Example:
    {[
      let l = [1; 2; 3] in
      let l' = 0 :: l in
      Memgraph_kitty.show ["l", l; "l'", l']
    ]}


    [Poly.show] is similar to [show] but can be used to display the
    representation of values of different OCaml types.

    Example (note the redefinition of the list syntax in [Poly] to implement
    heterogeneous lists):
    {[
      let l = [1; 2] in
      let p = (l, 0 :: l) in
      Memgraph_kitty.Poly.(show ["l", l; "p", p])
    ]}
*)

(** Display the memory representation of a list of labeled values *)
val show : (string * 'a) list -> unit

module Poly : sig
  type elist =
    | [] : elist
    | (::) : ((string * 'a) * elist) -> elist

  (** Display the memory representation of a list of labeled values, which can
      be of different OCaml types. *)
  val show : elist -> unit
end

(** Set display settings *)
val configure :
  ?scale : float ->
  ?external_node_color : string option ->
  ?block_node_color : string option ->
  ?root_node_color : string option ->
  ?outline_color : string ->
  ?background_color : string option ->
  ?direction : [`Vertical | `Horizontal] ->
  unit ->
  unit
