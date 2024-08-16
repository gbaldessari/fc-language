%{
#include "parser.tab.h"
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
%}

%%
"//".*                  { /* Ignorar comentarios de una sola línea */ }
[0-9]+                  { yylval.num = atoi(yytext); return NUMBER; }
\"([^\\\"]|\\.)*\"      { yylval.str = strdup(yytext + 1); yylval.str[strlen(yylval.str) - 1] = '\0'; return STRING; }
"true"                  { yylval.num = 1; return BOOLEAN; }
"false"                 { yylval.num = 0; return BOOLEAN; }
"papu"                 { return PRINT; }
"when"                  { return IF; }
"but"                   { return ELSE; }
"while"                 { return WHILE; }
"&&"                    { return AND; }
"||"                    { return OR; }
"!"                     { return NOT; }
"="                     { return ASSIGN; }
"("                     { return LPAREN; }
")"                     { return RPAREN; }
"{"                     { return LBRACE; }
"}"                     { return RBRACE; }
":v"                    { return SEMICOLON; }
"+"                     { return PLUS; }
"-"                     { return MINUS; }
"*"                     { return MULT; }
"/"                     { return DIV; }
"=="                    { return EQ; }
"<="                    { return LE; }
">="                    { return GE; }
"<"                     { return LT; }
">"                     { return GT; }
"!="                    { return NE; }

[a-zA-Z_][a-zA-Z0-9_]*  { yylval.str = strdup(yytext); return IDENTIFIER; }
[ \t\n]+                { /* Ignorar espacios en blanco */ }
.                       { printf("Carácter inesperado: %s\n", yytext); exit(1); }
%%

int yywrap() {
    return 1;
}
