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

static int count_depth(const char *s) {
    int spaces = 0;
    for (; *s; s++) {
        if (*s == ' ') spaces++;
        else if (*s == '\t') spaces += 4;
        else break;
    }
    return spaces / 4;
}

static list_item_t *mk_list_item(const char *text, int depth, int ordered) {
    list_item_t *item = malloc(sizeof(list_item_t));
    if (!item) return NULL;
    item->depth = depth;
    item->ordered = ordered;
    item->text = dup_trim(text);
    return item;
}
%}

%option noinput nounput noyywrap yylineno
%x BQ LIST

%%
<INITIAL>{
^[ \t]*[-+*][ \t]+[^\n]*\r?\n? {
    int depth = count_depth(yytext);
    const char *p = yytext;
    while (*p == ' ' || *p == '\t') p++;
    p++; /* skip marker */
    while (*p == ' ' || *p == '\t') p++;
    yylval.list = mk_list_item(p, depth, 0);
    BEGIN(LIST);
    return UL_ITEM;
}
^[ \t]*[0-9]+[.][ \t]+[^\n]*\r?\n? {
    int depth = count_depth(yytext);
    const char *p = yytext;
    while (*p == ' ' || *p == '\t') p++;
    while (*p && *p != '.') p++;
    if (*p == '.') p++;
    while (*p == ' ' || *p == '\t') p++;
    yylval.list = mk_list_item(p, depth, 1);
    BEGIN(LIST);
    return OL_ITEM;
}
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

<LIST>{
^[ \t]*[-+*][ \t]+[^\n]*\r?\n? {
    int depth = count_depth(yytext);
    const char *p = yytext;
    while (*p == ' ' || *p == '\t') p++;
    p++;
    while (*p == ' ' || *p == '\t') p++;
    yylval.list = mk_list_item(p, depth, 0);
    return UL_ITEM;
}
^[ \t]*[0-9]+[.][ \t]+[^\n]*\r?\n? {
    int depth = count_depth(yytext);
    const char *p = yytext;
    while (*p == ' ' || *p == '\t') p++;
    while (*p && *p != '.') p++;
    if (*p == '.') p++;
    while (*p == ' ' || *p == '\t') p++;
    yylval.list = mk_list_item(p, depth, 1);
    return OL_ITEM;
}
^[ \t]*\r?\n {
    BEGIN(INITIAL);
    return LIST_END;
}
^[^\n]* {
    BEGIN(INITIAL);
    yyless(0);
    return LIST_END;
}
<<EOF>> {
    if (YY_START == LIST) {
        BEGIN(INITIAL);
        return LIST_END;
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
