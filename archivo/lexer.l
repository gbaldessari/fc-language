%{
#include "parser.tab.h"
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
%}

%%
"//".*                        { /* Ignorar comentarios de una sola línea */ }
[0-9]+                        { yylval.num = atoi(yytext); return NUMBER; }
"+"                           { return PLUS; }
"-"                           { return MINUS; }
"*"                           { return MULT; }
"/"                           { return DIV; }
"("                           { return LPAREN; }
")"                           { return RPAREN; }
";"                           { return SEMICOLON; }
"print"                       { return PRINT; }
"="                           { return '='; } // Add this line to handle the '=' character
[a-zA-Z_][a-zA-Z0-9_]*        { yylval.str = strdup(yytext); return IDENTIFIER; }
[ \t\n]+                      { /* Ignorar espacios en blanco y nuevas líneas */ }
.                             { printf("Unexpected character: %s\n", yytext); }

%%

int yywrap() {
    return 1;
}
