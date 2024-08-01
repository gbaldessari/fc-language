%{
#include "parser.tab.h"
#include <stdio.h>
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
\n                            { /* Ignorar nuevas líneas */ }
[ \t]                         { /* Ignorar espacios en blanco */ }
.                             { /* Ignorar otros caracteres */ }
%%

int yywrap() {
    return 1;
}
