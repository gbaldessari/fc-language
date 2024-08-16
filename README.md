# Compiler comands

flex lexer.lex
bison -dv parser.y
gcc -o App lex.yy.c parser.tab.c

pwsh:
    Get-Content input.papu | ./App

bash:
    ./App < input.papu
