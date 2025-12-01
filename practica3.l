%{
#include <string.h>
#include <stdlib.h>
#include "practica3.tab.h"

static char *dup_trim(const char *s) {
    char *copy = strdup(s);
    if (!copy) return NULL;
    size_t len = strlen(copy);
    while (len > 0 && (copy[len - 1] == ' ' || copy[len - 1] == '\t' || copy[len - 1] == '\r' || copy[len - 1] == '\n')) {
        copy[--len] = '\0';
    }
    return copy;
}

static char *clean_heading(const char *s) {
    while (*s == ' ' || *s == '\t') s++;
    while (*s == '#') s++;
    while (*s == ' ' || *s == '\t') s++;
    return dup_trim(s);
}

static char *clean_bq(const char *s) {
    while (*s == ' ' || *s == '\t') s++;
    if (*s == '>') s++;
    while (*s == ' ' || *s == '\t') s++;
    return dup_trim(s);
}
%}

%option noinput nounput noyywrap yylineno
%x BQ

%%
<INITIAL>{
^[ \t]*>[ \t]*\r?\n          { BEGIN(BQ); return BQBLANK; }
^[ \t]*>[ \t]*[^\n]*\r?\n?   { BEGIN(BQ); yylval.str = clean_bq(yytext); return BQLINE; }
^[ \t]*#{1}[ \t]+[^\n]*\r?\n? { yylval.str = clean_heading(yytext); return HEAD1; }
^[ \t]*#{2}[ \t]+[^\n]*\r?\n? { yylval.str = clean_heading(yytext); return HEAD2; }
^[ \t]*#{3}[ \t]+[^\n]*\r?\n? { yylval.str = clean_heading(yytext); return HEAD3; }
^[ \t]*#{4}[ \t]+[^\n]*\r?\n? { yylval.str = clean_heading(yytext); return HEAD4; }
^[ \t]*#{5}[ \t]+[^\n]*\r?\n? { yylval.str = clean_heading(yytext); return HEAD5; }
^[ \t]*#{6}[ \t]+[^\n]*\r?\n? { yylval.str = clean_heading(yytext); return HEAD6; }
}

<BQ>{
^[ \t]*>[ \t]*\r?\n        { return BQBLANK; }
^[ \t]*>[ \t]*[^\n]*\r?\n? { yylval.str = clean_bq(yytext); return BQLINE; }
^[^\n]* {
    BEGIN(INITIAL);
    yyless(0);
    return BQEND;
}
<<EOF>> {
    if (YY_START == BQ) {
        BEGIN(INITIAL);
        return BQEND;
    }
}
}

^[ \t]*=+[ \t]*\r?\n    { return UNDER1; }
^[ \t]*-+[ \t]*\r?\n    { return UNDER2; }

\*\*\* { return TRIPLE; }
___ { return TRIPLE; }
\*\* { return STRONG; }
__ { return STRONG; }
\* { return EMPH; }
_ { return EMPH; }

[ ]{2}\r?\n { return HARD_BREAK; }
\r?\n       { return NEWLINE; }
[ \t]+      { yylval.str = strdup(yytext); return SPACE; }
[^*_\n\r \t]+ { yylval.str = strdup(yytext); return WORD; }
%%
