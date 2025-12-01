%code requires {
#ifndef LIST_ITEM_T_DEFINED
#define LIST_ITEM_T_DEFINED
typedef struct list_item {
    int depth;
    int ordered;
    char *text;
} list_item_t;
#endif
}

%{
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include "practica3.tab.h"

static int list_stack[32];
static int list_depth = 0;

int yylex(void);
void yyerror(const char *s);
static void handle_list_item(list_item_t *item);
static void close_all_lists(void);

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
    list_item_t *list;
}

%token <str> HEAD1 HEAD2 HEAD3 HEAD4 HEAD5 HEAD6
%token <str> WORD SPACE
%token <str> BQLINE
%token STRONG EMPH TRIPLE HARD_BREAK NEWLINE
%token <str> CODE
%token <str> CODE_TEXT
%token UNDER1 UNDER2
%token LIST_END
%token CODE_FENCE_START CODE_FENCE_END
%token <list> UL_ITEM OL_ITEM
%token BQBLANK BQEND
%token HR

%type <str> inline_content inline_element strong_text emph_text triple_text
%type <str> strong_content strong_content_element emph_content emph_content_element triple_content triple_content_element
%type <str> bq_content bq_piece bq_line bq_blank
%type <str> list_block list_items list_item code_block code_lines

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
    | list_block
    | blockquote
    | code_block
    | horizontal_rule
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

blockquote
    : bq_content opt_bq_end { printf("\\begin{quote}\n%s\\end{quote}\n\n", $1); free($1); }
    ;

opt_bq_end
    : BQEND
    | /* empty */
    ;

bq_content
    : bq_piece                 { $$ = $1; }
    | bq_content bq_piece      { $$ = join($1, $2); }
    ;

bq_piece
    : bq_line
    | bq_blank
    ;

bq_line
    : BQLINE { $$ = wrap("", $1, "\n"); }
    ;

bq_blank
    : BQBLANK { $$ = strdup("\n"); }
    ;

list_block
    : { list_depth = 0; } list_items opt_list_end { close_all_lists(); printf("\n"); }
    ;

opt_list_end
    : LIST_END
    | 
    ;

list_items
    : list_item        { $$ = $1; }
    | list_items list_item { $$ = $1; }
    ;

list_item
    : UL_ITEM { handle_list_item($1); $$ = NULL; }
    | OL_ITEM { handle_list_item($1); $$ = NULL; }
    ;

code_block
    : CODE_FENCE_START code_lines CODE_FENCE_END {
        printf("\\begin{verbatim}\n%s\\end{verbatim}\n\n", $2 ? $2 : "");
        free($2);
      }
    ;

code_lines
    : CODE_TEXT               { $$ = $1; }
    | code_lines CODE_TEXT    { $$ = join($1, $2); }
    ;

horizontal_rule
    : HR               { printf("\\noindent\\rule{\\linewidth}{0.4pt}\n\n"); }
    | UNDER1           { printf("\\noindent\\rule{\\linewidth}{0.4pt}\n\n"); }
    | UNDER2           { printf("\\noindent\\rule{\\linewidth}{0.4pt}\n\n"); }
    ;

inline_content
    : inline_element                 { $$ = $1; }
    | inline_content inline_element  { $$ = join($1, $2); }
    ;

inline_element
    : WORD          { $$ = $1; }
    | SPACE         { $$ = $1; }
    | CODE          { $$ = wrap("\\texttt{", $1, "}"); }
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

static void handle_list_item(list_item_t *item) {
    if (!item) return;
    int desired = item->depth + 1;
    if (desired < 1) desired = 1;
    if (desired > 32) desired = 32;
    while (list_depth > desired) {
        list_depth--;
        if (list_stack[list_depth]) printf("\\end{enumerate}\n");
        else printf("\\end{itemize}\n");
    }
    if (list_depth == desired && list_depth > 0 && list_stack[list_depth - 1] != item->ordered) {
        list_depth--;
        if (list_stack[list_depth]) printf("\\end{enumerate}\n");
        else printf("\\end{itemize}\n");
    }
    while (list_depth < desired) {
        if (item->ordered) printf("\\begin{enumerate}\n");
        else printf("\\begin{itemize}\n");
        list_stack[list_depth++] = item->ordered;
    }
    printf("\\item %s\n", item->text ? item->text : "");
    free(item->text);
    free(item);
}

static void close_all_lists(void) {
    while (list_depth > 0) {
        list_depth--;
        if (list_stack[list_depth]) printf("\\end{enumerate}\n");
        else printf("\\end{itemize}\n");
    }
}

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
