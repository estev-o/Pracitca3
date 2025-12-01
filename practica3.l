%{
#include <string.h>
#include <stdlib.h>
#include "practica3.tab.h"
%}

%option noinput nounput noyywrap yylineno

%%


^[ \t]*>    { return GT; }
>           { return GT; }

#           { return HASH; }

\*\*\*      { return TRIPLE; }
___         { return TRIPLE; }
\*\*        { return STRONG; }
__          { return STRONG; }
\*          { return EMPH; }
_           { return EMPH; }

[ ]{2}\r?\n { return HARD_BREAK; }
\r?\n       { return NEWLINE; }
[ \t]+      { yylval.str = strdup(yytext); return SPACE; }
[^*_>\n\r \t#]+ { yylval.str = strdup(yytext); return WORD; }

.           { yylval.str = strdup(yytext); return WORD; }

<<EOF>>     { static int once = 0; if (once++) return 0; return NEWLINE; }

%%
