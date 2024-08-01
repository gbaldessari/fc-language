%{
#include "parser.tab.h"
#include <string.h>
%}

%option noyywrap

%%

[0-9]+                { yylval.num = atoi(yytext); return NUMBER; }
"+"                   { return PLUS; }
"-"                   { return MINUS; }
"*"                   { return TIMES; }
"/"                   { return DIVIDE; }
"="                   { return ASSIGN; }
"if"                  { return IF; }
"else"                { return ELSE; }
"while"               { return WHILE; }
"print"               { return PRINT; }
"function"            { return FUNCTION; }
"return"              { return RETURN; }
[a-zA-Z_][a-zA-Z0-9_]* { yylval.str = strdup(yytext); return IDENTIFIER; }
"("                   { return LPAREN; }
")"                   { return RPAREN; }
"{"                   { return LBRACE; }
"}"                   { return RBRACE; }
"\n"                  { return EOL; }

[ \t]                 { /* skip whitespace */ }
.                     { fprintf(stderr, "Unknown character: %s\n", yytext); }

%%

