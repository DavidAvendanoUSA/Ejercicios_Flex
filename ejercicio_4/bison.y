%{
#include <stdio.h>
#include <stdlib.h>

extern int yylex(void);
extern void yyerror(const char *s);
%}

%union {
    int val;
    char mystery_char;
}

%token <val> NUMBER
%token ADD SUB MUL DIV ABS EOL
%token <mystery_char> MYSTERY

%%
stream:
    /* vacio */
    | stream element
    ;

element:
    NUMBER   { printf("258 = %d\n", $1); }
    | ADD    { printf("259\n"); }
    | SUB    { printf("260\n"); }
    | MUL    { printf("261\n"); }
    | DIV    { printf("262\n"); }
    | ABS    { printf("263\n"); }
    | EOL    { printf("264\n"); }
    | MYSTERY { printf("Mystery character %c\n", $1); }
    ;

%%

void yyerror(const char *s) {
    fprintf(stderr, "Error: %s\n", s);
}

int main(void) {
    yyparse();
    return 0;
}
