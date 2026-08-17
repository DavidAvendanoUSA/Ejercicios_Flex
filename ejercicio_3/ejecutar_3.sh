rm bison.tab.c
rm bison.tab.h
rm lex.yy.c
rm ejercicio_3 

bison -d bison.y

flex flex.l

gcc -o ejercicio_3  bison.tab.c lex.yy.c

./ejercicio_3
