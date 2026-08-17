%{
#include <stdlib.h>
#include "bison.tab.h"
%}

%option noyywrap

%%
"+"     { return ADD; }
"-"     { return SUB; }
"*"     { return MUL; }
"/"     { return DIV; }
"|"     { return ABS; }
[0-9]+  { yylval.val = atoi(yytext); return NUMBER; }
\n      { return EOL; }
[ \t]   { /* ignorar espacios */ }
.       { yylval.mystery_char = *yytext; return MYSTERY; }
%%
