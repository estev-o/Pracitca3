%code requires {
#ifndef LIST_ITEM_T_DEFINED
#define LIST_ITEM_T_DEFINED
typedef struct list_item {
    int depth;
    int ordered;
    char *text;
} list_item_t;

typedef struct link {
    char *text;
    char *url;
    char *title;
} link_t;
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

char* join(char* s1, char* s2) { // lo usamos para concatenar cadenas
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

char* wrap(char* prefix, char* s, char* suffix) { // lo usamos para crear cadenas de LaTeX
    if (!s) s = strdup("");
    char* res = malloc(strlen(prefix) + strlen(s) + strlen(suffix) + 1);
    if (!res) { fprintf(stderr, "Malloc failed\n"); exit(1); }
    strcpy(res, prefix);
    strcat(res, s);
    strcat(res, suffix);
    free(s);
    return res;
}

static void rtrim(char *s) { // elimina espacios en blanco al final de una cadena
    if (!s) return;
    size_t len = strlen(s);
    while (len > 0 && (s[len - 1] == ' ' || s[len - 1] == '\t' || s[len - 1] == '\n' || s[len - 1] == '\r')) {
        s[--len] = '\0';
    }
}

char* escape_latex(const char* s) {
    if (!s) return strdup("");
    char* res = calloc(strlen(s) * 20 + 1, 1);
    if (!res) { fprintf(stderr, "Malloc failed\n"); exit(1); }
    for (size_t i = 0; s[i]; i++) {
        switch (s[i]) {
            case '_': strcat(res, "\\_"); break;
            case '#': strcat(res, "\\#"); break;
            case '$': strcat(res, "\\$"); break;
            case '%': strcat(res, "\\%"); break;
            case '&': strcat(res, "\\&"); break;
            case '{': strcat(res, "\\{"); break;
            case '}': strcat(res, "\\}"); break;
            case '\\': strcat(res, "\\textbackslash{}"); break;
            case '^': strcat(res, "\\textasciicircum{}"); break;
            case '~': strcat(res, "\\textasciitilde{}"); break;
            case '<': strcat(res, "\\textless{}"); break;
            case '>': strcat(res, "\\textgreater{}"); break;
            default: {
                char temp[2] = {s[i], '\0'};
                strcat(res, temp);
            }
        }
    }
    return res;
}
%}

%union {
    char *str;
    list_item_t *list;
    link_t *link;
}

%token <str> HEAD1 HEAD2 HEAD3 HEAD4 HEAD5 HEAD6
%token <str> WORD SPACE
%token <str> BQLINE
%token STRONG EMPH TRIPLE HARD_BREAK
%token <str> CODE
%token <str> CODE_TEXT
%token LIST_END
%token CODE_FENCE_START CODE_FENCE_END
%token <list> UL_START OL_START
%token LIST_ITEM_END
%token BQBLANK BQEND
%token HR
%token UNDER1 UNDER2
%token BLANK
%token <link> LINK
%token <link> IMAGE

%type <str> inline_content inline_element strong_text emph_text triple_text
%type <str> strong_content strong_content_element emph_content emph_content_element triple_content triple_content_element
%type <str> bq_content bq_piece bq_line bq_blank
%type <str> list_block list_items list_item code_block code_lines

%nonassoc HARD_BREAK

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
    | horizontal_line
    | blank
    ;

heading
    : HEAD1        { char *e = escape_latex($1); printf("\\section{%s}\n\n", e); free(e); free($1); }
    | HEAD2        { char *e = escape_latex($1); printf("\\subsection{%s}\n\n", e); free(e); free($1); }
    | HEAD3        { char *e = escape_latex($1); printf("\\subsubsection{%s}\n\n", e); free(e); free($1); }
    | HEAD4        { char *e = escape_latex($1); printf("\\paragraph{%s}\n\n", e); free(e); free($1); }
    | HEAD5        { char *e = escape_latex($1); printf("\\subparagraph{%s}\n\n", e); free(e); free($1); }
    | HEAD6        { char *e = escape_latex($1); printf("\\textbf{%s}\n\n", e); free(e); free($1); }
    | inline_content UNDER1 { rtrim($1); printf("\\section{%s}\n\n", $1); free($1); }
    | inline_content UNDER2 { rtrim($1); printf("\\subsection{%s}\n\n", $1); free($1); }
    ;

paragraph
    : inline_content BLANK { rtrim($1); printf("%s\n\\newline\n\n", $1); free($1); }
    ;

blockquote
    : bq_content BQEND { printf("\\begin{quote}\n%s\\end{quote}\n\n", $1); free($1); }
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
    : BQLINE { char *esc = escape_latex($1); $$ = wrap("", esc, "\n"); free($1); }
    ;

bq_blank
    : BQBLANK { $$ = strdup("\n"); }
    ;

list_block
    : { list_depth = 0; } list_items LIST_END { close_all_lists(); printf("\n"); }
    ;

list_items
    : list_item        { $$ = $1; }
    | list_items list_item { $$ = $1; }
    ;

list_item
    : UL_START inline_content LIST_ITEM_END { $1->text = $2; rtrim($1->text); handle_list_item($1); $$ = NULL; }
    | UL_START LIST_ITEM_END { $1->text = strdup(""); handle_list_item($1); $$ = NULL; }
    | OL_START inline_content LIST_ITEM_END { $1->text = $2; rtrim($1->text); handle_list_item($1); $$ = NULL; }
    | OL_START LIST_ITEM_END { $1->text = strdup(""); handle_list_item($1); $$ = NULL; }
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

horizontal_line
    : HR               { printf("\\noindent\\rule{\\linewidth}{0.4pt}\n\n"); }
    | UNDER1           { printf("\\noindent\\rule{\\linewidth}{0.4pt}\n\n"); }
    | UNDER2           { printf("\\noindent\\rule{\\linewidth}{0.4pt}\n\n"); }
    ;

inline_content
    : inline_element                 { $$ = $1; }
    | inline_content inline_element  { $$ = join($1, $2); }
    ;

inline_element
    : WORD          { $$ = escape_latex($1); free($1); }
    | SPACE         { $$ = $1; }
    | HARD_BREAK    { $$ = strdup(" \\\\\n"); }
    | CODE          { char *e = escape_latex($1); $$ = wrap("\\texttt{", e, "}"); free($1); }
    | LINK          {
            char *raw_text = $1->text ? strdup($1->text) : ($1->url ? strdup($1->url) : strdup(""));
            char *text = escape_latex(raw_text);
            free(raw_text);

            if ($1->url) {
                char *href = wrap("\\href{", $1->url ? strdup($1->url) : strdup(""), "}{");
                char *body = join(href, text);
                $$ = wrap(body, strdup(""), "}");
                free(body);
            } else {
                $$ = text;
            }
            free($1->text);
            free($1->url);
            free($1->title);
            free($1);
        }
    | IMAGE         {
            char *url = $1->url ? strdup($1->url) : strdup("");
            char *cmd = wrap("\\includegraphics[width=\\textwidth]{", url, "}");
            $$ = cmd;
            free($1->text);
            free($1->url);
            free($1->title);
            free($1);
        }
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
    : BLANK { }
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
    printf("\\documentclass{article}\n");
    printf("\\usepackage[utf8]{inputenc}\n");
    printf("\\usepackage[T1]{fontenc}\n");
    printf("\\usepackage{hyperref}\n\\usepackage{graphicx}\n\\begin{document}\n");
    int res = yyparse();
    printf("\n\\end{document}\n");
    return res;
}
