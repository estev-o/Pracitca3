FUENTE = practica3
PRUEBA = tests/basic.md
TEX_OUT = $(PRUEBA:.md=.tex)
PDF_OUT = $(PRUEBA:.md=.pdf)
LIB = lfl

all: compile run

compile:
	flex $(FUENTE).l
	bison -o $(FUENTE).tab.c $(FUENTE).y -yd
	gcc -o $(FUENTE) lex.yy.c $(FUENTE).tab.c -$(LIB) -ly

run: compile $(PRUEBA)
	./$(FUENTE) < $(PRUEBA) > $(TEX_OUT)

clean:
	rm -f $(FUENTE) lex.yy.c $(FUENTE).tab.c $(FUENTE).tab.h $(TEX_OUT) $(PDF_OUT)

.PHONY: all compile run clean
