
rm bison.tab.c
rm bison.tab.h
rm lex.yy.c
rm ejercicio_4 

bison -d bison.y

flex flex.l

gcc -o ejercicio_4  bison.tab.c lex.yy.c

./ejercicio_4

