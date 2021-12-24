
# Representation of closures


## Introduction

OCaml needs to represent sets of closures, wich, in the general cases,
contain: a set of mutually recursive functions and a number of environment
values (also called environment variables). For instance, let's consider
the following ocaml code:

```ocaml
let test () =
  (* we use Random here to ensure that `n` is
     not a compile-time constant *)
  let n = Random.int 10 in

  (* Two mutually recursive functions. Since we're only interested
     in the representation of the closures, the runtime behaviour
     of the functions doesn't matter (e.g. it's not a problem that
     the functions do not terminate) *)
  let rec f x y = n + n + y + g x
  and g y = f y (y + 1) in

  f
```

In this case, we have two mutually recursive functions `f` and `g`,
and one environment variable `n`.


## General layout of a set of closures

A set of closures in ocaml is represented as a regular ocaml block
with tag `Obj.closure_tag`. That block contains first all of the
mutually recursive closures, and then[^1] will contain all of the
environment values. Additionally, each closure (except for the first),
is preceded by an infix header, that is an integer field that contains
an offset (more on that later) and the tag `Obj.infix_tag`.

[^1]: Note that starting from ocaml 4.12, this is a strict requirement
  on sets of closures. Indeed, starting from 4.12, sets of closures now
  record the offset in the block at which the environment start, and
  the GC will only scan the fields of the block starting form this offset.
  Before 4.12, the GC scanned all fields, and used the page table to
  distinguish code pointers.

```verbatim
  |----------------------------|
  | header (tag= closure_tag)  |
  |----------------------------|
  | First closure (e.g. `f`)   | <- pointer used to represent `f`
  |                            |    (i.e. the first closure)
  |                            |
  |----------------------------|
  | Infix header               |
  |----------------------------|
  | Second closure (e.g. `g`)  | <- pointer used to represent `g`
  |                            |    (i.e. the second closure)
  |                            |
  |----------------------------|
  .                            .
  .                            .
  .                            .
  |----------------------------|
  | Infix header               |
  |----------------------------|
  | Last closure               |
  |                            |
  |                            |
  |----------------------------|
  | First env value            | <- start of env
  |----------------------------|
  | Second env value           |
  |----------------------------|
  .                            .
  .                            .
  .                            .
  |----------------------------|
  | Last env value             |
  |----------------------------|
```

TODO: add note on the potential presence of holes when using flambda2
(and flambda ? ask @lthls for some precisions)



## Representation of a single closure

### General case

The representation of a single closure is a bit complicated. In general,
for a closure with arity strictly greateer than 1 (i.e. a function which
takes at least two arguments), a closure is represented using three words:
- First is a function pointer that can be used when the funciton is supplied
  one argument (and thus results in a partial application). Let's call
  this one the "currified" pointer for the closure.
- Second is an integer field that encodes two integers: the arity of the
  function, and the offset of the start of environment for the set of closure,
  relative to the offset of the closure.
- Lastly is a function pointer that can be used for total application, i.e.
  when the number of arguments provided is the same as the arity of the function.
  Let's call this one the "total" pointer for the closure.


```verbatim
  .                                .
  |--------------------------------|
  | header                         |
  |--------------------------------|
  | "currified" function pointer   | <- pointer (inside the set of closures)
  |--------------------------------|    used to represent the closure
  | closure info (arity+startenv)  |
  |--------------------------------|
  | "total" function pointer       |
  |--------------------------------|
  .                                .
```

### Functions of arity 1

As a special case, functions that have an arity of `1` are represented using
only two words. Indeed, for these functions, the "currified" and the "total"
function pointers are actually the same, and thus the last function pointer
is not present.

```verbatim
  .                                .
  |--------------------------------|
  | header                         |
  |--------------------------------|
  | function pointer               | <- pointer (inside the set of closures)
  |--------------------------------|    used to represent the closure
  | closure info (arity+startenv)  |
  |--------------------------------|
  .                                .
```

### Closure info

The closure info field of closures has a different representation depending
on the version of ocaml used

#### ocaml 4.11 and earlier

Beofre 4.12, only the arity was encoded in the closure info field. That field was
an integer field, so was represented by the tagged integer of the arity:

```
arity ((wordsize - 1) bits) . 1
```

#### ocaml 4.12 and later

Starting from ocaml 4.12, the closure info field encodes both the arity of the
closure, and the offset of the start of environment for the set of closures.
It is still a integer field, so is represented as a tagged integer:

```
arity (8 bits) . start-of-environment ((wordsize - 9) bits) . 1
```

## Infix headers

Except for the first one, each closure representaiton in a set of closures
need to be preceded by an infix header. That header is similar to a regular
ocaml block header, except that is has the infix tag (e.g. `Obj.infix_tag`),
and that the size information of the header is actually used to identify
the start of the set of closure block. To that effect, the "size" stored in
the header is actually the offset **in bytes** of the closure representation
inside the set of closures.

Note that this is specific to infix headers. For other header, the size
is in general, the number of fields/words that make up the block (excluding
the word used for the header). This is true as weel for


## Examples

### Full set of closures example

Let's consider the example from the introduction:

```ocaml
let test () =
  let n = Random.int 10 in

  let rec f x y = n + n + y + g x
  and g y = f y (y + 1) in

  f
```

We need to represent a set of closures that contain two functions: `f` (arity=2),
and `g` (arity=1), and one env value: `n`.

Assuming a 64-bit host (and thus 8 bytes per word),
this results in the following layout:


```verbatim
                                 offset/field number
  |----------------------------|
  | header (closure_tag,size=6)|
  |----------------------------|
  | "caml_curry2"              | 0       <- start of closure `f` (offset=0)
  |----------------------------|
  | {arity=2,startenv=6}       | 1
  |----------------------------|
  | function pointer of `f`    | 2
  |----------------------------|
  | header (infix_tag,size=32) | 3       :: size = 32 = 8 * 4 (offset of the start of the closure for `g`)
  |----------------------------|
  | function pointer of `g`    | 4       <- start of closure `g` (offset=4)
  |----------------------------|
  | {arity=1,startenv=2}       | 5       :: startenv = 2 = 6 (absolute startenv) - 4 (offset of `g`)
  |----------------------------|
  | value of <n>               | 6       <- start of env (offset=6)
  |----------------------------|
```

Notes:
- the closure `f` starts at offset `0`
- the closure `g` starts at offset `4`
- the environment starts at offset `6`
- the set of closures header has size 6 (since the set uses 6 words
  (excluding the whole block header) to be represented)
- the start of env in the closure info fields are relative to the offset of the closure,
  so it is:
  - `6` for `f`, whose offset is `0`, since it is the first closure
  - `2` for `g`, whose offset if `4` (since the env starts 2 words after the start of `g`)
- the size stored insied the infix tag is `32`, since it is interpreted as the number of
  bytes to substract to the start of `g` to get the start of the whole set of closures



