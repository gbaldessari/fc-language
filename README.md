# Lenguaje de programación básico
Lenguaje de programación básico para la asignatura Fundamentos de la Computación

# Consola
Common: 
```
flex lexer.lex
bison -dv parser.y
gcc -o App lex.yy.c parser.tab.c
```
Powershell:
```
Get-Content input.ps | ./App 
```
bash:
```
./App < input.ps
```
