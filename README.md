flex lexer.l
bison -dv parser.y
gcc -o App lex.yy.c parser.tab.c

Get-Content input.txt | ./App
