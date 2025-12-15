%{
#include <string.h>
#include <stdlib.h>
#include "practica3.tab.h"

// Copiamos una cadena y le quitamos espacios en blanco al final
static char *dup_trim(const char *s) {
    char *copy = strdup(s);
    if (!copy) return NULL;
    size_t len = strlen(copy);
    while (len > 0 && (copy[len - 1] == ' ' || copy[len - 1] == '\t' || copy[len - 1] == '\r' || copy[len - 1] == '\n')) {
        copy[--len] = '\0';
    }
    return copy;
}

// Copiamos una cadena limpiando el encabezado
static char *clean_heading(const char *s) {
    while (*s == ' ' || *s == '\t') s++;
    while (*s == '#') s++;
    while (*s == ' ' || *s == '\t') s++;
    return dup_trim(s);
}

// Copiamos una cadena limpiando el bloque de cita
static char *clean_bq(const char *s) {
    while (*s == ' ' || *s == '\t') s++;
    if (*s == '>') s++;
    while (*s == ' ' || *s == '\t') s++;
    return dup_trim(s);
}

// Calculamos profundidad de anidamiento de listas
static int count_depth(const char *s) {
    int spaces = 0;
    for (; *s; s++) {
        if (*s == ' ') spaces++;
        else if (*s == '\t') spaces += 4;
        else break;
    }
    return spaces / 4;
}

// Estructura de lista en la que guardamos profundidad, tipo y texto
static list_item_t *mk_list_item(const char *text, int depth, int ordered) {
    list_item_t *item = malloc(sizeof(list_item_t));
    if (!item) return NULL;
    item->depth = depth;
    item->ordered = ordered;
    item->text = dup_trim(text);
    return item;
}

static int fence_char = 0; //Qué simbolo cierra el code fence
static int eof_sent = 0; // Evita bucles infinitos al final del archivo

//Estructura para links e imágenes con text, URL y título
static link_t *mk_link(const char *text, const char *url, const char *title) {
    link_t *l = malloc(sizeof(link_t));
    if (!l) return NULL;
    l->text = text ? strdup(text) : NULL;
    l->url = url ? strdup(url) : NULL;
    l->title = title ? strdup(title) : NULL;
    return l;
}
%}

%option noinput nounput noyywrap yylineno
%x BQ LIST CFENCE

%%
<INITIAL>{
^[ \t]*\*{3,}[ \t]*\r?\n? { return HR; } /* Lineas horizontales */
^[ \t]*_{3,}[ \t]*\r?\n? { return HR; }

^```[^\n]*\r?\n?  { fence_char = '`'; BEGIN(CFENCE); return CODE_FENCE_START; } /* Código */
^~~~[^\n]*\r?\n?  { fence_char = '~'; BEGIN(CFENCE); return CODE_FENCE_START; }

^[ \t]*[-+*][ \t]+[^\n]*\r?\n? {
    int depth = count_depth(yytext);
    const char *p = yytext;
    while (*p == ' ' || *p == '\t') p++;
    p++; /* skip marker */
    while (*p == ' ' || *p == '\t') p++;
    yylval.list = mk_list_item(p, depth, 0);
    BEGIN(LIST);
    return UL_ITEM;
} /* Lista no ordenada */
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
} /* Lista ordenada */

^[ \t]*>[ \t]*\r?\n          { BEGIN(BQ); return BQBLANK; } /* Cita */
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

<CFENCE>{
^```[ \t]*\r?\n?  { if (fence_char == '`') { BEGIN(INITIAL); return CODE_FENCE_END; } }
^~~~[ \t]*\r?\n?  { if (fence_char == '~') { BEGIN(INITIAL); return CODE_FENCE_END; } }
^[^\n]*\r?\n? {
    yylval.str = strdup(yytext);
    return CODE_TEXT;
}
<<EOF>> {
    if (YY_START == CFENCE) {
        BEGIN(INITIAL);
        return CODE_FENCE_END;
    }
}
}

^[ \t]*=+[ \t]*\r?\n    { return UNDER1; }
^[ \t]*-+[ \t]*\r?\n    { return UNDER2; }

\*\*\* { return TRIPLE; } /* Negrita y cursiva */
___ { return TRIPLE; }
\*\* { return STRONG; }
__ { return STRONG; }
\* { return EMPH; }
_ { return EMPH; }

`[^`\n\r]*` {
    size_t len = yyleng;
    if (len >= 2) {
        char *copy = malloc(len - 1);
        if (copy) {
            memcpy(copy, yytext + 1, len - 2);
            copy[len - 2] = '\0';
            yylval.str = copy;
            return CODE;
        }
    }
}

[ ]{2}\r?\n { return HARD_BREAK; }
^[ \t]*\r?\n { return BLANK; }
\r?\n       { yylval.str = strdup(" "); return SPACE; }
[ \t]+      { yylval.str = strdup(yytext); return SPACE; }
\[[^]]+\]\([^) \t\n\r]+[^)\n\r]*\) { /* Link */
    const char *p = yytext + 1;
    const char *end_text = strchr(p, ']');
    const char *url_start = strchr(end_text ? end_text : p, '(');
    if (end_text && url_start) {
        size_t text_len = end_text - p;
        char *text = strndup(p, text_len);
        url_start++;
        while (*url_start == ' ' || *url_start == '\t') url_start++;
        const char *url_end = strchr(url_start, ')');
        char *inner = NULL;
        if (url_end && url_end > url_start) inner = strndup(url_start, url_end - url_start);
        char *url = NULL;
        char *title = NULL;
        if (inner) {
            char *space = strchr(inner, ' ');
            if (space) {
                *space = '\0';
                char *tstart = strchr(space + 1, '"');
                if (tstart) {
                    tstart++;
                    char *tend = strchr(tstart, '"');
                    if (tend) title = strndup(tstart, tend - tstart);
                }
            }
            url = strdup(inner);
        }
        yylval.link = mk_link(text, url, title);
        free(text);
        free(url);
        free(title);
        free(inner);
        return LINK;
    }
}
[!]\[[^]]*\]\([^) \t\n\r]+[^)\n\r]*\) { /* Imagen */
    const char *p = yytext + 2;
    const char *end_text = strchr(p, ']');
    const char *url_start = strchr(end_text ? end_text : p, '(');
    if (end_text && url_start) {
        size_t text_len = end_text - p;
        char *alt = strndup(p, text_len);
        url_start++;
        while (*url_start == ' ' || *url_start == '\t') url_start++;
        const char *url_end = strchr(url_start, ')');
        char *inner = NULL;
        if (url_end && url_end > url_start) inner = strndup(url_start, url_end - url_start);
        char *url = NULL;
        char *title = NULL;
        if (inner) {
            char *space = strchr(inner, ' ');
            if (space) {
                *space = '\0';
                char *tstart = strchr(space + 1, '"');
                if (tstart) {
                    tstart++;
                    char *tend = strchr(tstart, '"');
                    if (tend) title = strndup(tstart, tend - tstart);
                }
            }
            url = strdup(inner);
        }
        yylval.link = mk_link(alt, url, title);
        free(alt);
        free(url);
        free(title);
        free(inner);
        return IMAGE;
    }
}
[<]https?:[^>\n\r]+[>] {
    size_t len = yyleng;
    char *url = strndup(yytext + 1, len - 2);
    yylval.link = mk_link(url, url, NULL);
    free(url);
    return LINK;
}
[<][^>\n\r@]+@[^>\n\r]+[>] {
    size_t len = yyleng;
    char *url = strndup(yytext + 1, len - 2);
    yylval.link = mk_link(url, url, NULL);
    free(url);
    return LINK;
}
<<EOF>> {
    if (!eof_sent) {
        eof_sent = 1;
        return BLANK;
    }
    return 0;
}
[^*_\n\r \t]+ { yylval.str = strdup(yytext); return WORD; }
%%
