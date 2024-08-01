%{
#include <stdio.h>
#include <stdlib.h>

void yyerror(const char *s);
int yylex();

%}

%union {
    int num;
}

%token <num> NUMBER
%token PLUS MINUS MULT DIV
%token LPAREN RPAREN SEMICOLON
%token PRINT

%type <num> expression

%left PLUS MINUS
%left MULT DIV

%%

program:
    lines
    ;

lines:
    line
    | lines line
    ;

line:
    print_statement SEMICOLON
    ;

print_statement:
    PRINT LPAREN expression RPAREN { printf("%d\n", $3); }
    | PRINT LPAREN RPAREN          { printf("\n"); } // Manejar print() sin expresión
    ;

expression:
    NUMBER                        { $$ = $1; }
    | expression PLUS expression  { $$ = $1 + $3; }
    | expression MINUS expression { $$ = $1 - $3; }
    | expression MULT expression  { $$ = $1 * $3; }
    | expression DIV expression   { $$ = $1 / $3; }
    | LPAREN expression RPAREN    { $$ = $2; }
    ;

%%

void yyerror(const char *s) {
    fprintf(stderr, "Error: %s\n", s);
}

int main() {
    yyparse();
    return 0;
}
