flex papu-tokens.l
bison -dv papu-parser.y
gcc -o App lex.yy.c papu-parser.tab.c

Get-Content input.txt | ./App
