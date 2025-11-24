%{
#include <stdio.h>
#include <stdlib.h>

int yylex(void);
void yyerror(const char *s);
%}

%union {
    char *str;
}

%token <str> HEAD1 HEAD2 HEAD3 HEAD4 HEAD5 HEAD6
%token <str> TEXTLINE
%token UNDER1 UNDER2
%token NEWLINE
%start document

%%
document
    : elements
    ;

elements
    : /* empty */
    | elements element
    ;

element
    : heading
    | textline
    | blank
    ;

heading
    : HEAD1        { printf("\\section{%s}\n\n", $1); free($1); }
    | HEAD2        { printf("\\subsection{%s}\n\n", $1); free($1); }
    | HEAD3        { printf("\\subsubsection{%s}\n\n", $1); free($1); }
    | HEAD4        { printf("\\paragraph{%s}\n\n", $1); free($1); }
    | HEAD5        { printf("\\subparagraph{%s}\n\n", $1); free($1); }
    | HEAD6        { printf("\\textbf{%s}\n\n", $1); free($1); }
    | TEXTLINE NEWLINE UNDER1 { printf("\\section{%s}\n\n", $1); free($1); }
    | TEXTLINE NEWLINE UNDER2 { printf("\\subsection{%s}\n\n", $1); free($1); }
    ;

textline
    : TEXTLINE NEWLINE { printf("%s\n", $1); free($1); }
    ;

blank
    : NEWLINE { printf("\n"); }
    ;
%%

void yyerror(const char *s) {
    fprintf(stderr, "Error: %s\n", s);
}

int main(void) {
    printf("\\documentclass{article}\n\\begin{document}\n");
    int res = yyparse();
    printf("\n\\end{document}\n");
    return res;
}
