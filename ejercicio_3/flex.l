%{
#include <string.h>
#include "bison.tab.h"
%}

%option noyywrap

%%
"+"     { return PLUS; }
"-"     { return MINUS; }
"*"     { return TIMES; }
"/"     { return DIVIDE; }
"|"     { return ABS; }
[0-9]+  { yylval.str = strdup(yytext); return NUMBER; }
\n      { return NEWLINE; }
[ \t]   { /* ignorar espacios */ }
.       { yylval.str = strdup(yytext); return MYSTERY; }
%%
