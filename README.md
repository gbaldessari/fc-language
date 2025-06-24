# Lenguaje de programación básico

Lenguaje de programación básico para la asignatura Fundamentos de la Computación

## Consola

Common:

```sh
flex lexer.lex
bison -dv parser.y
gcc -o App lex.yy.c parser.tab.c
```

Powershell:

```sh
Get-Content input.ps | ./App 
```

bash:

```sh
./App < input.ps
```
