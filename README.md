# Ejercicios de Flex & Bison

Este repositorio contiene la solución a los **ejercicios 3 y 4** de un taller de 5 ejercicios basado en el libro *flex & bison* (O'Reilly). Ambos ejercicios parten del mismo escáner de tokens (operadores aritméticos, números y el símbolo `|`) conectado a un parser de Bison, cada uno con una variante distinta de tipos de datos y de salida.

## Organización del proyecto

```
Ejercicios_Flex/
├── ejercicio_3/
│   ├── flex.l          → analizador léxico (escáner)
│   ├── bison.y          → gramática / parser
│   └── ejecutar_3.sh    → script que compila y corre el ejercicio
│
└── ejercicio_4/
    ├── flex.l
    ├── bison.y
    └── ejecutar_4.sh
```

Cada carpeta es independiente: trae su propio `flex.l`, `bison.y` y script de compilación, así que se pueden compilar y correr por separado.

> Al ejecutar `ejecutar_3.sh` / `ejecutar_4.sh` se generan automáticamente dentro de cada carpeta los archivos `bison.tab.c`, `bison.tab.h`, `lex.yy.c` y el ejecutable (`ejercicio_3` / `ejercicio_4`). Esos archivos los crea el compilador, no son código fuente escrito a mano — si quieres mantener el repo limpio, considera agregarlos a un `.gitignore`.

## Requisitos

- `flex`
- `bison`
- `gcc`

En Ubuntu/Debian o WSL:

```bash
sudo apt update
sudo apt install flex bison gcc
```

## Cómo ejecutar

**1. Clonar el repositorio**

```bash
git clone https://github.com/DavidAvendanoUSA/Ejercicios_Flex.git
cd Ejercicios_Flex
```

**2. Entrar a la carpeta del ejercicio**

```bash
cd ejercicio_3     # o ejercicio_4
```

**3. Dar permisos de ejecución al script**

```bash
chmod +x ejecutar_3.sh     # ejecutar_4.sh en el otro caso
```

Esto hace falta porque algunos métodos de descarga (por ejemplo bajar el repo como ZIP en vez de clonarlo) no conservan el permiso de ejecución del archivo.

**4. Ejecutar**

```bash
./ejecutar_3.sh
```

El script hace, en orden:

```bash
rm bison.tab.c bison.tab.h lex.yy.c ejercicio_3   # limpia una compilación anterior
bison -d bison.y                                    # genera bison.tab.c y bison.tab.h
flex flex.l                                          # genera lex.yy.c
gcc -o ejercicio_3 bison.tab.c lex.yy.c              # compila parser + escáner
./ejercicio_3                                        # corre el programa
```

> **Nota:** la primera vez que lo corras vas a ver mensajes como `rm: cannot remove 'bison.tab.c': No such file or directory`. Es normal: el script intenta borrar archivos de una compilación previa que todavía no existen. No afecta la compilación ni el resultado.

El programa lee de **entrada estándar**, así que después de ejecutarlo puedes:

- escribir una línea a mano y presionar `Enter` (`Ctrl+D` para terminar), o
- redirigir un archivo: `./ejercicio_3 < entrada.txt`, o
- usar un pipe: `echo "3 + 4 * |2|" | ./ejercicio_3`

---

## Ejercicio 3

`flex.l` reconoce el texto de entrada y le manda *tokens* a `bison.y` a través de `yylex()`; `bison.y` recibe esos tokens y, por cada uno, imprime en pantalla de qué token se trata.

### `flex.l` — el escáner

**Bloque 1 — Encabezado**
```c
%{
#include <string.h>
#include "bison.tab.h"
%}

%option noyywrap
```
Incluye `string.h` para poder usar `strdup()`, e incluye `bison.tab.h`: el header que genera `bison -d` con las constantes de los tokens (`PLUS`, `NUMBER`, etc.), para que `flex.l` y `bison.y` usen exactamente los mismos nombres. `%option noyywrap` le dice a flex que no hace falta la función `yywrap()` porque solo se procesa una entrada.

**Bloque 2 — Reglas de reconocimiento**
```c
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
```
- Los primeros 5 patrones son literales: cada operador matchea un solo carácter y devuelve su token.
- `[0-9]+` reconoce uno o más dígitos seguidos. Copia el texto reconocido (`yytext`) con `strdup()` —porque `yytext` se sobreescribe en el siguiente match, hay que guardarlo aparte— y devuelve `NUMBER`.
- `\n` devuelve `NEWLINE`.
- `[ \t]` descarta espacios y tabulaciones sin devolver nada.
- `.` es la regla "atrapa todo": cualquier carácter que no calzó arriba (letras, `@`, `~`, etc.) se guarda igual que un número, pero se devuelve como `MYSTERY`.

### `bison.y` — la gramática

**Bloque 1 — Unión de tipos**
```c
%union {
    char *str;
}
```
Declara que el valor semántico de un token (`yylval`) puede ser un `char *`. Es el campo que `flex.l` llena con `strdup()`.

**Bloque 2 — Declaración de tokens**
```c
%token PLUS MINUS TIMES DIVIDE ABS NEWLINE
%token <str> NUMBER MYSTERY
```
`PLUS`...`NEWLINE` no llevan valor asociado, solo importa que ocurrieron. `NUMBER` y `MYSTERY` sí usan el campo `str` de la unión (por eso `<str>`).

**Bloque 3 — Gramática y acciones**
```c
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
```
`tokens` es la típica regla recursiva para "cero o más elementos": puede estar vacía, o ser `tokens` seguido de un `token_item` más, así acepta cualquier cantidad de tokens seguidos. Por cada uno imprime una línea describiéndolo. En `NUMBER` y `MYSTERY`, `$1` es el valor semántico (la cadena que guardó `flex.l`) y se libera con `free()` justo después de usarla, porque `strdup` reservó memoria dinámica que hay que liberar.

**Bloque 4 — `main`**
```c
void yyerror(const char *s) {
    fprintf(stderr, "Error: %s\n", s);
}

int main(void) {
    yyparse();
    return 0;
}
```
`yyerror` la llama Bison automáticamente si hay un error de sintaxis (acá casi nunca pasa, porque la gramática acepta cualquier secuencia de tokens). `main` solo arranca el análisis con `yyparse()`, que internamente va pidiendo tokens llamando a `yylex()` cada vez que los necesita.

### Ejemplo

Entrada:
```
3 + 4 * |2|
@
```

Salida:
```
NUMBER 3
PLUS
NUMBER 4
TIMES
ABS
NUMBER 2
ABS
NEWLINE
Mystery character @
NEWLINE
```

---

## Ejercicio 4

Parte del mismo escáner que el ejercicio 3, pero cambia dos cosas: en vez de guardar el texto reconocido como cadena, guarda **valores tipados de verdad** (`int` para los números, `char` para el carácter misterioso); y en vez de imprimir el nombre del token, imprime el **código numérico interno** que Bison le asignó a cada uno.

### `flex.l`

**Bloque 1 — Encabezado**
```c
%{
#include <stdlib.h>
#include "bison.tab.h"
%}

%option noyywrap
```
Ahora incluye `stdlib.h` en vez de `string.h`, porque usa `atoi()` en vez de `strdup()`.

**Bloque 2 — Reglas**
```c
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
```
Los nombres de los tokens cambiaron (`ADD`, `SUB`, `MUL`, `DIV`, `EOL` en vez de `PLUS`, `MINUS`, `TIMES`, `DIVIDE`, `NEWLINE` — es solo cosmético), pero lo que importa es el tipo del valor guardado:
- Para `NUMBER`, `atoi(yytext)` convierte el texto directamente a `int` y lo guarda en `yylval.val`.
- Para `MYSTERY`, `*yytext` toma solo el primer carácter (un `char` suelto, no una cadena) y lo guarda en `yylval.mystery_char`.

### `bison.y`

**Bloque 1 — Unión con dos tipos**
```c
%union {
    int val;
    char mystery_char;
}
```
A diferencia del ejercicio 3 (que solo tenía `char *str`), acá la unión tiene dos miembros de tipos distintos: uno para números y otro para el carácter misterioso. Cada token usa el que le corresponde.

**Bloque 2 — Tokens**
```c
%token <val> NUMBER
%token ADD SUB MUL DIV ABS EOL
%token <mystery_char> MYSTERY
```

**Bloque 3 — Gramática: se imprimen los códigos internos**
```c
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
```
Bison le asigna automáticamente a cada `%token` con nombre un número entero — así es como realmente viaja la información entre `yylex()` y `yyparse()`; nombres como `NUMBER` o `ADD` son solo etiquetas para que el código sea legible para nosotros. Esos códigos quedan definidos en el `bison.tab.h` que se genera al compilar:

| Token     | Código |
|-----------|:------:|
| `NUMBER`  | 258 |
| `ADD`     | 259 |
| `SUB`     | 260 |
| `MUL`     | 261 |
| `DIV`     | 262 |
| `ABS`     | 263 |
| `EOL`     | 264 |
| `MYSTERY` | 265 |

Empiezan en 258 porque Bison reserva internamente el 0 para fin de archivo, el 256 para errores y el 257 para "token no reconocido"; los tokens definidos por el usuario arrancan justo después. Este ejercicio imprime esos números directamente en cada `printf` para comprobar que coinciden con lo que Bison generó. Además, para `NUMBER` también se imprime el valor entero real que se parseó (`$1`).

**Bloque 4 — `main`**
```c
void yyerror(const char *s) {
    fprintf(stderr, "Error: %s\n", s);
}

int main(void) {
    yyparse();
    return 0;
}
```
Igual que en el ejercicio 3: `yyerror` para errores de sintaxis, `main` arranca el análisis con `yyparse()`.

### Ejemplo

Entrada:
```
3 + 42 * |2|
@
```

Salida:
```
258 = 3
259
258 = 42
261
263
258 = 2
263
264
Mystery character @
264
```

---

## Agregar este README al repo

```bash
# desde la raíz del repo, con este archivo ya copiado ahí
git add README.md
git commit -m "Agregar README con organizacion del proyecto y explicacion de ejercicios 3 y 4"
git push
```
