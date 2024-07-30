%{
#include "papu-parser.tab.h"
#include <string.h> // Necesario para strdup

int yylineno = 1; // Definimos yylineno aquí
%}

%%
[0-9]+      {
    yylval.num = atoi(yytext);
    printf("TOKEN: NUMBER(%d)\n", yylval.num);
    return NUMBER;
}
[a-zA-Z]+   {
    yylval.id = strdup(yytext);
    printf("TOKEN: IDENTIFIER(%s)\n", yylval.id);
    return IDENTIFIER;
}
\+          {
    printf("TOKEN: PLUS\n");
    return PLUS;
}
\-          {
    printf("TOKEN: MINUS\n");
    return MINUS;
}
\*          {
    printf("TOKEN: MULTIPLY\n");
    return MULTIPLY;
}
\/          {
    printf("TOKEN: DIVIDE\n");
    return DIVIDE;
}
\n          {
    yylineno++;
    printf("TOKEN: NEWLINE\n");
    return '\n';
}
[ \t]+      { /* Ignora espacios y tabulaciones */ }
.           { /* Ignora caracteres no reconocidos */ }
%%

int yywrap() {
    return 1;
}
