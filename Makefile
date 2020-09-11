# copyright (c) 2020, guillaume bury

COMP=dune
FLAGS=

all: dune

watch:
	dune build $(FLAGS) -w @check

dune:
	dune build $(FLAGS) @install

doc:
	dune build $(FLAGS) @doc

doc-html: doc
	xdg-open _build/default/_doc/_html/index.html

ex:
	dune build $(FLAGS) @examples

clean:
	$(COMP) clean

.PHONY: all watch dune bin test doc clean
