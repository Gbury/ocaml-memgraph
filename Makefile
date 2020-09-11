# copyright (c) 2020, guillaume bury

COMP=dune
FLAGS=

all: dune

watch:
	dune build $(FLAGS) -w @check
	@echo

dune:
	dune build $(FLAGS) @install
	@echo

doc:
	dune build $(FLAGS) @doc
	@echo

doc-html: doc
	xdg-open _build/default/_doc/_html/index.html

ex:
	dune build $(FLAGS) @examples
	@echo

clean:
	$(COMP) clean

.PHONY: all watch dune bin test doc clean
