# copyright (c) 2014, guillaume bury

LOG=build.log
COMP=ocamlbuild -log $(LOG) -use-ocamlfind -classic-display
FLAGS=
DIRS=
DOC=

TEST=test.native
NAME=memgraph

LIB=$(addprefix $(NAME), .cma .cmxa .cmxs)

all: lib

lib:
	$(COMP) $(FLAGS) $(DIRS) $(LIB)

test: test-build
	rm -f temp.gv
	./$(TEST)
	dot -Txlib temp.gv

test-build:
	$(COMP) $(FLAGS) $(DIRS) $(TEST)

doc:
	$(COMP) $(FLAGS) $(DIRS) $(DOC)

log:
	cat _build/$(LOG) || true

clean:
	$(COMP) -clean

.PHONY: clean doc all
