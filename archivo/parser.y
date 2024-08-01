%{
#include <stdio.h>
#include <stdlib.h>
#include <string.h>

void yyerror(const char *s);
int yylex();
int yyparse();
int yydebug = 1;  // Enable debugging

// Estructura para almacenar variables
typedef struct {
    char *name;
    int value;
} variable;

#define MAX_VARS 100
variable vars[MAX_VARS];
int num_vars = 0;

// Funciones para manejar variables
int get_var_value(const char *name);
void set_var_value(const char *name, int value);

%}

%union {
    int num;
    char *str;
}

%token <num> NUMBER
%token PLUS MINUS MULT DIV
%token LPAREN RPAREN SEMICOLON
%token PRINT
%token <str> IDENTIFIER
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
    | assignment SEMICOLON
    ;

print_statement:
    PRINT LPAREN expression RPAREN { printf("%d\n", $3); }
    | PRINT LPAREN RPAREN          { printf("\n"); }
    ;

assignment:
    IDENTIFIER '=' expression {
        set_var_value($1, $3);
        free($1);  // Liberar la memoria del identificador
    }
    ;

expression:
    NUMBER                        { $$ = $1; }
    | IDENTIFIER                  { $$ = get_var_value($1); }
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
    yydebug = 1;  // Enable debugging
    yyparse();
    return 0;
}

int get_var_value(const char *name) {
    for (int i = 0; i < num_vars; i++) {
        if (strcmp(vars[i].name, name) == 0) {
            return vars[i].value;
        }
    }
    fprintf(stderr, "Error: Variable '%s' not found\n", name);
    exit(EXIT_FAILURE);
}

void set_var_value(const char *name, int value) {
    for (int i = 0; i < num_vars; i++) {
        if (strcmp(vars[i].name, name) == 0) {
            vars[i].value = value;
            return;
        }
    }
    if (num_vars < MAX_VARS) {
        vars[num_vars].name = strdup(name);
        vars[num_vars].value = value;
        num_vars++;
    } else {
        fprintf(stderr, "Error: Too many variables\n");
        exit(EXIT_FAILURE);
    }
}
