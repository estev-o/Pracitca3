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
%}

%option noinput nounput noyywrap

%%
^[ \t]*#{1,6}[ \t]+[^\n]*\r?\n? {
    /* Count heading level */
    int i = 0, level = 0;
    while (yytext[i] == ' ' || yytext[i] == '\t') i++;
    while (yytext[i] == '#') { level++; i++; }
    while (yytext[i] == ' ' || yytext[i] == '\t') i++;
    char *text = dup_trim(yytext + i);
    yylval.str = text;
    switch (level) {
        case 1: return HEAD1;
        case 2: return HEAD2;
        case 3: return HEAD3;
        case 4: return HEAD4;
        case 5: return HEAD5;
        case 6: return HEAD6;
        default: free(text); break;
    }
}

^[ \t]*=+[ \t]*\r?\n    { return UNDER1; }
^[ \t]*-+[ \t]*\r?\n    { return UNDER2; }

^[^\n]+ {
    yylval.str = dup_trim(yytext);
    return TEXTLINE;
}

\r?\n    { return NEWLINE; }
%%
