# copyright (c) 2014, guillaume bury

LOG=build.log
COMP=ocamlbuild -log $(LOG) -use-ocamlfind -classic-display
FLAGS=
DOC=

NAME=memgraph
EXAMPLES_ML=$(shell ls examples/*.ml)
EXAMPLES_SVG=$(EXAMPLES_ML:.ml=.svg)

LIB=$(addprefix $(NAME), .cma .cmxa .cmxs)

all: lib

lib:
	$(COMP) $(FLAGS) $(LIB)

ex: $(EXAMPLES_SVG)

%.svg: %.gv
	dot -Tsvg $< -o $@

%.gv: %.native
	./$< > $@

%.native: %.ml
	$(COMP) $(FLAGS) $@
	mv $(notdir $@) $@

doc:
	$(COMP) $(FLAGS) $(DOC)

clean:
	rm -f $(TEST) temp.gv
	rm -f examples/*.{svg,gv,native}
	$(COMP) -clean

.PHONY: clean doc all

