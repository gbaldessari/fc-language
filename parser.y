%{
#include <stdio.h>
#include <stdlib.h>
#include <string.h>

#define MAX_FUNCTIONS 100

void yyerror(const char *s);
int yylex(void);

typedef int (*func_ptr)(int);

typedef struct {
    char *name;
    func_ptr func;
} function_t;

function_t functions[MAX_FUNCTIONS];
int func_count = 0;

int call_function(char *name, int arg) {
    for (int i = 0; i < func_count; i++) {
        if (strcmp(functions[i].name, name) == 0) {
            return functions[i].func(arg);
        }
    }
    fprintf(stderr, "Function %s not defined\n", name);
    return 0;
}

int fibonacci(int n) {
    if (n <= 1) return n;
    return fibonacci(n-1) + fibonacci(n-2);
}

void add_function(char *name, func_ptr func) {
    if (func_count < MAX_FUNCTIONS) {
        functions[func_count].name = name;
        functions[func_count].func = func;
        func_count++;
    } else {
        fprintf(stderr, "Function limit reached\n");
    }
}

%}

%union {
    int num;
    char *str;
}

%token <num> NUMBER
%token IF ELSE WHILE PRINT FUNCTION RETURN
%token <str> IDENTIFIER
%token PLUS MINUS TIMES DIVIDE ASSIGN
%token LPAREN RPAREN LBRACE RBRACE EOL

%left PLUS MINUS
%left TIMES DIVIDE
%nonassoc IFX
%nonassoc ELSE

%type <num> expr
%type <str> identifier

%%

program:
    program statement
    | /* empty */
    ;

statement:
    expr EOL { printf("Resultado: %d\n", $1); }
    | PRINT expr EOL { printf("Resultado: %d\n", $2); }
    | IF LPAREN expr RPAREN statement %prec IFX
    | IF LPAREN expr RPAREN statement ELSE statement
    | WHILE LPAREN expr RPAREN statement
    | LBRACE program RBRACE
    | FUNCTION identifier LPAREN identifier RPAREN LBRACE program RETURN expr RBRACE {
        add_function($2, fibonacci);
    }
    | identifier LPAREN expr RPAREN EOL { printf("Resultado: %d\n", call_function($1, $3)); }
    ;

expr:
    NUMBER
    | expr PLUS expr { $$ = $1 + $3; }
    | expr MINUS expr { $$ = $1 - $3; }
    | expr TIMES expr { $$ = $1 * $3; }
    | expr DIVIDE expr { $$ = $1 / $3; }
    | LPAREN expr RPAREN { $$ = $2; }
    | identifier LPAREN expr RPAREN { $$ = call_function($1, $3); }
    ;

identifier:
    IDENTIFIER { $$ = $1; }
    ;

%%

void yyerror(const char *s) {
    fprintf(stderr, "Error: %s\n", s);
}
