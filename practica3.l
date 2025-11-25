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
%}

%option noinput nounput noyywrap

%%
^[ \t]*#{1}[ \t]+[^\n]*\r?\n? { yylval.str = clean_heading(yytext); return HEAD1; }
^[ \t]*#{2}[ \t]+[^\n]*\r?\n? { yylval.str = clean_heading(yytext); return HEAD2; }
^[ \t]*#{3}[ \t]+[^\n]*\r?\n? { yylval.str = clean_heading(yytext); return HEAD3; }
^[ \t]*#{4}[ \t]+[^\n]*\r?\n? { yylval.str = clean_heading(yytext); return HEAD4; }
^[ \t]*#{5}[ \t]+[^\n]*\r?\n? { yylval.str = clean_heading(yytext); return HEAD5; }
^[ \t]*#{6}[ \t]+[^\n]*\r?\n? { yylval.str = clean_heading(yytext); return HEAD6; }

^[ \t]*=+[ \t]*\r?\n    { return UNDER1; }
^[ \t]*-+[ \t]*\r?\n    { return UNDER2; }

^.*[ ]{2}\r? {
    yylval.str = dup_trim(yytext);
    return TEXTLINE_HARD_BREAK;
}

^[^\n]+ {
    yylval.str = dup_trim(yytext);
    return TEXTLINE;
}

\r?\n    { return NEWLINE; }
%%
