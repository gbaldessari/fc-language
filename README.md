flex lexer.l
bison -dv parser.y
gcc -o App lex.yy.c parser.tab.c

#Para utilizar en cualquiera de las 2 terminales solo se necesita ./App

pwsh:
    Get-Content input.papu | ./App

bash:
    ./App < input.papu