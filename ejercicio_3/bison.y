%{
#include <stdio.h>
#include <stdlib.h>

extern int yylex(void);
extern void yyerror(const char *s);
%}

%union {
    char *str;
}

%token PLUS MINUS TIMES DIVIDE ABS NEWLINE
%token <str> NUMBER MYSTERY

%%
tokens:
    /* vacio */
    | tokens token_item
    ;

token_item:
    PLUS      { printf("PLUS\n"); }
    | MINUS   { printf("MINUS\n"); }
    | TIMES   { printf("TIMES\n"); }
    | DIVIDE  { printf("DIVIDE\n"); }
    | ABS     { printf("ABS\n"); }
    | NUMBER  { printf("NUMBER %s\n", $1); free($1); }
    | NEWLINE { printf("NEWLINE\n"); }
    | MYSTERY { printf("Mystery character %s\n", $1); free($1); }
    ;

%%

void yyerror(const char *s) {
    fprintf(stderr, "Error: %s\n", s);
}

int main(void) {
    yyparse();
    return 0;
}
