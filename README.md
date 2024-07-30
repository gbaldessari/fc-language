default:
	clear
	flex -l papu-tokens.l
	bison -dv papu-parser.y 
	gcc -o App papu-parser.tab.c lex.yy.c 