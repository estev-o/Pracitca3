%{
#include <stdio.h>
#include <stdlib.h>
#include <string.h>

int yylex(void);
void yyerror(const char *s);

char* join(char* s1, char* s2) {
    if (!s1) return s2 ? s2 : strdup("");
    if (!s2) return s1;
    char* res = malloc(strlen(s1) + strlen(s2) + 1);
    if (!res) { fprintf(stderr, "Malloc failed\n"); exit(1); }
    strcpy(res, s1);
    strcat(res, s2);
    free(s1);
    free(s2);
    return res;
}

char* wrap(char* prefix, char* s, char* suffix) {
    if (!s) s = strdup("");
    char* res = malloc(strlen(prefix) + strlen(s) + strlen(suffix) + 1);
    if (!res) { fprintf(stderr, "Malloc failed\n"); exit(1); }
    strcpy(res, prefix);
    strcat(res, s);
    strcat(res, suffix);
    free(s);
    return res;
}
%}

%union {
    char *str;
}

%token <str> HEAD1 HEAD2 HEAD3 HEAD4 HEAD5 HEAD6
%token <str> WORD SPACE
%token STRONG EMPH TRIPLE HARD_BREAK NEWLINE
%token UNDER1 UNDER2

%type <str> inline_content inline_element strong_text emph_text triple_text
%type <str> strong_content strong_content_element emph_content emph_content_element triple_content triple_content_element

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
    | paragraph
    | blank
    ;

heading
    : HEAD1        { printf("\\section{%s}\n\n", $1); free($1); }
    | HEAD2        { printf("\\subsection{%s}\n\n", $1); free($1); }
    | HEAD3        { printf("\\subsubsection{%s}\n\n", $1); free($1); }
    | HEAD4        { printf("\\paragraph{%s}\n\n", $1); free($1); }
    | HEAD5        { printf("\\subparagraph{%s}\n\n", $1); free($1); }
    | HEAD6        { printf("\\textbf{%s}\n\n", $1); free($1); }
    | inline_content NEWLINE UNDER1 { printf("\\section{%s}\n\n", $1); free($1); }
    | inline_content HARD_BREAK UNDER1 { printf("\\section{%s}\n\n", $1); free($1); }
    | inline_content NEWLINE UNDER2 { printf("\\subsection{%s}\n\n", $1); free($1); }
    | inline_content HARD_BREAK UNDER2 { printf("\\subsection{%s}\n\n", $1); free($1); }
    ;

paragraph
    : inline_content NEWLINE { printf("%s\n", $1); free($1); }
    | inline_content HARD_BREAK { printf("%s \\\\\n", $1); free($1); }
    ;

inline_content
    : inline_element                 { $$ = $1; }
    | inline_content inline_element  { $$ = join($1, $2); }
    ;

inline_element
    : WORD          { $$ = $1; }
    | SPACE         { $$ = $1; }
    | strong_text   { $$ = $1; }
    | emph_text     { $$ = $1; }
    | triple_text   { $$ = $1; }
    ;

strong_text
    : STRONG strong_content STRONG { $$ = wrap("\\textbf{", $2, "}"); }
    ;

strong_content
    : strong_content_element                 { $$ = $1; }
    | strong_content strong_content_element  { $$ = join($1, $2); }
    ;

strong_content_element
    : WORD          { $$ = $1; }
    | SPACE         { $$ = $1; }
    | emph_text     { $$ = $1; }
    | triple_text   { $$ = $1; }
    ;

emph_text
    : EMPH emph_content EMPH { $$ = wrap("\\textit{", $2, "}"); }
    ;

emph_content
    : emph_content_element                 { $$ = $1; }
    | emph_content emph_content_element  { $$ = join($1, $2); }
    ;

emph_content_element
    : WORD          { $$ = $1; }
    | SPACE         { $$ = $1; }
    | strong_text   { $$ = $1; }
    | triple_text   { $$ = $1; }
    ;

triple_text
    : TRIPLE triple_content TRIPLE { $$ = wrap("\\textbf{\\textit{", $2, "}}"); }
    ;

triple_content
    : triple_content_element                 { $$ = $1; }
    | triple_content triple_content_element  { $$ = join($1, $2); }
    ;

triple_content_element
    : WORD          { $$ = $1; }
    | SPACE         { $$ = $1; }
    | strong_text   { $$ = $1; }
    | emph_text     { $$ = $1; }
    ;

blank
    : NEWLINE { printf("\n"); }
    ;
%%

extern int yylineno;
void yyerror(const char *s) {
    fprintf(stderr, "Error: %s at line %d\n", s, yylineno);
}

int main(void) {
    printf("\\documentclass{article}\n\\begin{document}\n");
    int res = yyparse();
    printf("\n\\end{document}\n");
    return res;
}
