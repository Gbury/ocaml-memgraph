
type tag = private int
type addr = private int

type cell = private
  | Abstract
  | Int of int
  | Double of float
  | String of string
  | Pointer of addr

and block = private {
  addr : addr; (* unique int to preserve sharing *)
  tag : tag;
  fields : cell array;
}

val follow : addr -> block

val repr : 'a -> cell

