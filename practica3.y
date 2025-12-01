%{
#include <stdio.h>
#include <stdlib.h>
#include <string.h>

int yylex(void);
void yyerror(const char *s);

/* Helper functions for string manipulation */
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

/* Helper to generate heading tags based on level */
char* make_heading(int level, char* content) {
    char* prefix;
    switch(level) {
        case 1: prefix = "\\section{"; break;
        case 2: prefix = "\\subsection{"; break;
        case 3: prefix = "\\subsubsection{"; break;
        case 4: prefix = "\\paragraph{"; break;
        case 5: prefix = "\\subparagraph{"; break;
        default: prefix = "\\textbf{"; break; 
    }
    return wrap(prefix, content, level > 5 ? "}\n\n" : "}\n\n");
}
%}

%union {
    char *str;
    int num;
}

%token <str> WORD SPACE
%token HASH GT STRONG EMPH TRIPLE HARD_BREAK NEWLINE

/* Precedence to resolve ambiguity in inline formatting */
%nonassoc STRONG EMPH TRIPLE

%type <str> doc blocks block
%type <str> heading paragraph blockquote blank
%type <str> inline atom strong emph triple
%type <str> inline_opt non_special_start non_space_inline
%type <str> strong_content strong_atom
%type <str> emph_content emph_atom
%type <str> triple_content triple_atom
%type <num> hashes

%start doc

%%

doc
    : blocks { printf("%s", $1); free($1); }
    ;

blocks
    : block          { $$ = $1; }
    | blocks block   { $$ = join($1, $2); }
    ;

block
    : heading        { $$ = $1; }
    | paragraph      { $$ = $1; }
    | blockquote     { $$ = $1; }
    | blank          { $$ = $1; }
    | SPACE block    { $$ = $2; free($1); }
    ;

heading
    : hashes SPACE inline NEWLINE { $$ = make_heading($1, $3); free($2); }
    ;

hashes
    : HASH          { $$ = 1; }
    | hashes HASH   { $$ = $1 + 1; }
    ;

blockquote
    : GT block          { $$ = wrap("\\begin{quote}\n", $2, "\\end{quote}\n\n"); }
    ;

paragraph
    : non_special_start inline_opt NEWLINE  { $$ = join($1, join($2, strdup("\n"))); }
    | non_special_start inline_opt HARD_BREAK { $$ = join($1, join($2, strdup(" \\\\\n"))); }
    | hashes non_space_inline inline_opt NEWLINE { 
        /* Paragraph starting with hashes but not a heading (e.g. #foo or # without space) */
        char* h_str = malloc($1 + 1);
        memset(h_str, '#', $1);
        h_str[$1] = '\0';
        $$ = join(h_str, join($2, join($3, strdup("\n"))));
    }
    | hashes non_space_inline inline_opt HARD_BREAK { 
        char* h_str = malloc($1 + 1);
        memset(h_str, '#', $1);
        h_str[$1] = '\0';
        $$ = join(h_str, join($2, join($3, strdup(" \\\\\n"))));
    }
    | hashes NEWLINE {
        /* Paragraph consisting only of hashes */
        char* h_str = malloc($1 + 1);
        memset(h_str, '#', $1);
        h_str[$1] = '\0';
        $$ = join(h_str, strdup("\n"));
    }
    | hashes HARD_BREAK {
        char* h_str = malloc($1 + 1);
        memset(h_str, '#', $1);
        h_str[$1] = '\0';
        $$ = join(h_str, strdup(" \\\\\n"));
    }
    ;

blank
    : NEWLINE { $$ = strdup("\n"); }
    ;

inline_opt
    : /* empty */   { $$ = strdup(""); }
    | inline        { $$ = $1; }
    ;

inline
    : atom          { $$ = $1; }
    | inline atom   { $$ = join($1, $2); }
    ;

atom
    : WORD          { $$ = $1; }
    | SPACE         { $$ = $1; }
    | HASH          { $$ = strdup("#"); }
    | GT            { $$ = strdup(">"); }
    | strong        { $$ = $1; }
    | emph          { $$ = $1; }
    | triple        { $$ = $1; }
    ;

non_special_start
    : WORD          { $$ = $1; }
    | strong        { $$ = $1; }
    | emph          { $$ = $1; }
    | triple        { $$ = $1; }
    ;

non_space_inline
    : WORD          { $$ = $1; }
    | GT            { $$ = strdup(">"); }
    | strong        { $$ = $1; }
    | emph          { $$ = $1; }
    | triple        { $$ = $1; }
    ;

strong_content
    : strong_atom                   { $$ = $1; }
    | strong_content strong_atom    { $$ = join($1, $2); }
    ;

strong_atom
    : WORD          { $$ = $1; }
    | SPACE         { $$ = $1; }
    | HASH          { $$ = strdup("#"); }
    | GT            { $$ = strdup(">"); }
    | emph          { $$ = $1; }
    | triple        { $$ = $1; }
    ;

emph_content
    : emph_atom                 { $$ = $1; }
    | emph_content emph_atom    { $$ = join($1, $2); }
    ;

emph_atom
    : WORD          { $$ = $1; }
    | SPACE         { $$ = $1; }
    | HASH          { $$ = strdup("#"); }
    | GT            { $$ = strdup(">"); }
    | strong        { $$ = $1; }
    | triple        { $$ = $1; }
    ;

triple_content
    : triple_atom                   { $$ = $1; }
    | triple_content triple_atom    { $$ = join($1, $2); }
    ;

triple_atom
    : WORD          { $$ = $1; }
    | SPACE         { $$ = $1; }
    | HASH          { $$ = strdup("#"); }
    | GT            { $$ = strdup(">"); }
    | strong        { $$ = $1; }
    | emph          { $$ = $1; }
    ;

strong
    : STRONG strong_content STRONG { $$ = wrap("\\textbf{", $2, "}"); }
    ;

emph
    : EMPH emph_content EMPH     { $$ = wrap("\\textit{", $2, "}"); }
    ;

triple
    : TRIPLE triple_content TRIPLE { $$ = wrap("\\textbf{\\textit{", $2, "}}"); }
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
