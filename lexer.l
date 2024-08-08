%{
#include "parser.tab.h"
#include <stdio.h>
#include <stdlib.h>
#include <string.h>

// Declaraciones necesarias para los buffers de Flex
YY_BUFFER_STATE yy_scan_string(const char *str);
void yypush_buffer_state(YY_BUFFER_STATE new_buffer);
void yypop_buffer_state(void);
void yy_delete_buffer(YY_BUFFER_STATE buffer);
void yy_switch_to_buffer(YY_BUFFER_STATE new_buffer);

%}

%%
"//".*                  { /* Ignorar comentarios de una sola línea */ }
[0-9]+                  { yylval.num = atoi(yytext); return NUMBER; }
"true"                  { yylval.num = 1; return BOOLEAN; }
"false"                 { yylval.num = 0; return BOOLEAN; }
"print"                 { return PRINT; }
"if"                    { return IF; }
"&&"                    { return AND; }
"||"                    { return OR; }
"!"                     { return NOT; }
"="                     { return ASSIGN; }
"("                     { return LPAREN; }
")"                     { return RPAREN; }
"{"                     { return LBRACE; }
"}"                     { return RBRACE; }
";"                     { return SEMICOLON; }
"+"                     { return PLUS; }
"-"                     { return MINUS; }
"*"                     { return MULT; }
"/"                     { return DIV; }
[a-zA-Z_][a-zA-Z0-9_]*  { yylval.str = strdup(yytext); return IDENTIFIER; }
[ \t\n]+                { /* Ignorar espacios en blanco */ }
.                       { printf("Carácter inesperado: %s\n", yytext); exit(1); }
%%

int yywrap() {
    return 1;
}
