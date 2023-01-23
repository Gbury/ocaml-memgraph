
(** Representation of ocaml values

    This module aims at given a way to inspect the memory layout of ocaml
    values by providing some type to represent memory layouts, and some
    functions to convert arbitrary ocaml values into their explicit memory
    representation.
*)

(** {2 Type definitions} *)

type tag = private int
(** Ocaml tags *)

type addr = private int
(** Abstract addresses, used for sharing *)

type closinfo = {
  arity : int;
  start_of_env : int;
}
(** Contents of the closure info field, stored for each closure in a
    set of closures. *)

type block = private {
  addr : addr; (** unique int to preserve sharing *)
  tag  : tag;  (** Block tag *)
  data : data; (** Block contents *)
}
(** Represent OCaml blocks.
    - tag is the ocaml tag in the block header.
    - data is a high-level representation of the fields of the block.
    - addr is additional information used to keep track of sharing between values.
*)

and data =
  | Abstract
  | Block of [ `Block ] cell
  | Fields of [ `Inline ] cell array (**)
(** To have a high-level representation of a block's fields,
    we distinguish three cases:
    - some block are abstract and thus their contents cannot be inspected
    - the block contain a single big value (typically a string and/or a float)
    - the block contains an array of values. *)

and _ cell =
  | Int      : int          -> [< `Inline | `Direct ] cell  (** Integers *)
  | Pointer  : addr         -> [< `Inline | `Direct ] cell  (** Pointers to some block *)
  | External : Nativeint.t  -> [< `Inline ] cell            (** Out of heap pointer *)
  | String   : string       -> [< `Block ] cell             (** String *)
  | Double   : float        -> [< `Block | `Inline ] cell   (** A float *)
  | Infix    :                 [ `Inline ] cell             (** An infix header (used in closures) *)
  | Closinfo : closinfo     -> [< `Inline ] cell            (** Closure info field *)
(** The actual type of memory cells containing concrete values.
    There are actually three type of cells:
    - [`Direct] cells are values that can be found in ocaml variables
    - [`Inline] cells are values that can be found in a block's field array
    - [`Block]  cells are "big" values that take a whole block

    Obviously, some constructors can build more than one type of cells.
*)

type pblock = private {
  block   : block;  (** The block being pointed at *)
  offset  : int;    (** The offset in the block (used in mutually rec closures) *)
}
(** This represents what is pointed at by a pointer. This is useful considering that
    an ocaml value can point at a closure within a set of closures, and thus point
    in the middle of an ocaml value (since there is an infix header, the value being
    pointed to is also an ocaml value, but things are easier to represent this way). *)



(** {2 Manipulating values} *)

val follow : addr -> pblock
(** Follow a pointer. *)

val walk : (pblock -> unit) -> pblock -> unit
(** Apply the given function to a block, and all the blocks it points to
    (recursively). Each block is visited exactly once (the order is left
    unspecified though). *)


(** {2 Creating values} *)

val repr : 'a -> [ `Direct ] cell
(** Get the representation of a direct ocaml value. *)

type context = { mk : 'a. 'a -> [ `Direct ] cell }
(** A type containing a function to create cells. *)

val context : (context -> 'a) -> 'a
(** Allow to use the same context for creating values, i.e.
    all values created with [context.mk] will correctly
    identify shared values between translated values. *)

