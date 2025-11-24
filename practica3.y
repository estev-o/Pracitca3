%{
#include <stdio.h>

int yylex(void);
void yyerror(const char *s);
%}

%union {
    char c;
}

%token <c> CHAR
%start document

%%
document
    : content
    ;

content
    : /* empty */
    | content CHAR   { fputc($2, stdout); }
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
