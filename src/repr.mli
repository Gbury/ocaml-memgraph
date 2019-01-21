
(** {2 Type definitions} *)

type tag = int
(** Ocaml tags *)

type addr = int
(** Abstract addresses, used for sharing *)

type block = {
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
  | Fields of [ `Inline ] cell array
(** To have a high-level representation of a block's fields,
    we distinguish two cases: either the block contain a single big value
    (typically a string and/or a float), or it contains an array of values. *)

and _ cell =
  | Int      : int          -> [< `Inline | `Direct ] cell  (** Integers *)
  | Pointer  : addr         -> [< `Inline | `Direct ] cell  (** Pointers to some block *)
  | External : Nativeint.t  -> [< `Inline ] cell            (** Out of heap pointer *)
  | String   : string       -> [< `Block ] cell             (** String *)
  | Double   : float        -> [< `Block | `Inline ] cell   (** A float *)
  | Infix    :                 [ `Inline ] cell             (** An infix header (used in closures) *)
(** The actual type of memory cells containing real values.
    There are actually three type of cells:
    - [`Direct] cells are values that can be found in ocaml variables
    - [`Inline] cells are values that can be found in a block's field array
    - [`Block]  cells are "big" values that take a whole block

    Obviously, some constructors can build more than one type of cells.
*)

type pblock = {
  block   : block;  (** The block being pointed at *)
  offset  : int;    (** The offset in the block (used in mutually rec closures) *)
}
(** This represents what is pointed at by a pointer. *)



(** {2 Manipulating values} *)

val follow : addr -> pblock
(** Follow a pointer. *)

val walk : (pblock -> unit) -> pblock -> unit
(** Apply the given function to a block, and all the blocks it points to
    (recursively). *)


(** {2 Creating values} *)

val repr : 'a -> [ `Direct ] cell
(** Get the representation of a direct ocaml value. *)

type context = { mk : 'a. 'a -> [ `Direct ] cell }
(** A type containing a function to create cells. *)

val context : (context -> 'a) -> 'a
(** Allow to use the same context for creating values, i.e.
    all values creating with [context.mk] will faithfully make use of
    sharing. *)

