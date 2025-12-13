FUENTE = practica3
PRUEBA = tests/basic.md
TEX_OUT = $(PRUEBA:.md=.tex)
PDF_OUT = $(PRUEBA:.md=.pdf)
LIB = lfl

TEST_SRCS = $(wildcard tests/*.md)
TEST_OUTS = $(TEST_SRCS:.md=.tex)

all: compile run

compile:
	flex $(FUENTE).l
	bison -o $(FUENTE).tab.c $(FUENTE).y -yd
	gcc -o $(FUENTE) lex.yy.c $(FUENTE).tab.c -$(LIB)

run: compile $(PRUEBA)
	./$(FUENTE) < $(PRUEBA) > $(TEX_OUT)

runall: compile $(TEST_OUTS)

tests/%.tex: tests/%.md
	./$(FUENTE) < $< > $@

clean:
	rm -f $(FUENTE) lex.yy.c $(FUENTE).tab.c $(FUENTE).tab.h $(TEX_OUT) $(PDF_OUT) $(TEST_OUTS)

.PHONY: all compile run clean runall
