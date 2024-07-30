%{
#include <stdio.h>
#include <stdlib.h>
#include <string.h>

void yyerror(const char *s);
extern int yylex();
extern int yylineno; // Declaración de yylineno

typedef struct Symbol {
    char *name;
    int value;
    struct Symbol *next;
} Symbol;

Symbol *symbol_table = NULL;

Symbol *lookup(char *name) {
    for (Symbol *sym = symbol_table; sym != NULL; sym = sym->next) {
        if (strcmp(sym->name, name) == 0) {
            return sym;
        }
    }
    return NULL;
}

void insert(char *name, int value) {
    Symbol *sym = lookup(name);
    if (sym != NULL) {
        sym->value = value;
    } else {
        sym = (Symbol *)malloc(sizeof(Symbol));
        sym->name = strdup(name);
        sym->value = value;
        sym->next = symbol_table;
        symbol_table = sym;
    }
}

int get_value(char *name) {
    Symbol *sym = lookup(name);
    if (sym != NULL) {
        return sym->value;
    }
    yyerror("Undefined variable");
    return 0; // Valor por defecto si el símbolo no se encuentra
}
%}

%union {
    int num;
    char *id;
}

%token <num> NUMBER
%token <id> IDENTIFIER
%token PLUS MINUS MULTIPLY DIVIDE

%type <num> expression statement

%left PLUS MINUS
%left MULTIPLY DIVIDE

%%
program:
    program statement
    | /* vacío */
    ;

statement:
    IDENTIFIER '=' expression '\n' {
        insert($1, $3);
        printf("%s = %d\n", $1, $3);
        free($1);
    }
    | '\n' {
        // Permite líneas vacías para evitar errores de sintaxis
        printf("Empty line\n");
    }
    ;

expression:
    NUMBER {
        $$ = $1;
    }
    | IDENTIFIER {
        $$ = get_value($1);
    }
    | expression PLUS expression {
        $$ = $1 + $3;
    }
    | expression MINUS expression {
        $$ = $1 - $3;
    }
    | expression MULTIPLY expression {
        $$ = $1 * $3;
    }
    | expression DIVIDE expression {
        if ($3 == 0) {
            yyerror("Division by zero");
            $$ = 0;
        } else {
            $$ = $1 / $3;
        }
    }
    ;

%%
void yyerror(const char *s) {
    fprintf(stderr, "Error at line %d: %s\n", yylineno, s);
}

int main(void) {
    return yyparse();
}
