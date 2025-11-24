%{
#include "practica3.tab.h"
%}

%option noinput nounput noyywrap

%%
.|\n    { yylval.c = yytext[0]; return CHAR; }
%%
