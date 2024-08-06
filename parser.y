%{
#include <stdio.h>
#include <stdlib.h>
#include <string.h>

void yyerror(const char *s);
int yylex();

// Estructura para almacenar variables
typedef struct {
    char *name;
    int value;
    int is_boolean;
} variable;

#define MAX_VARS 100
variable vars[MAX_VARS];
int num_vars = 0;

// Funciones para manejar variables
variable get_var(const char *name);
void set_var_value(const char *name, int value, int is_boolean);

// Función para imprimir valores
void print_value(int value, int is_boolean) {
    if (is_boolean) {
        if (value) {
            printf("true\n");
        } else {
            printf("false\n");
        }
    } else {
        printf("%d\n", value);
    }
}

%}

%union {
    int num;
    char *str;
    struct {
        int value;
        int is_boolean;
    } exp;
}

%token <num> NUMBER BOOLEAN
%token PLUS MINUS MULT DIV
%token LPAREN RPAREN SEMICOLON
%token PRINT
%token <str> IDENTIFIER
%token AND OR NOT
%token ASSIGN
%type <exp> expression

%left OR
%left AND
%right NOT
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
    PRINT LPAREN expression RPAREN {
        print_value($3.value, $3.is_boolean);
    }
    | PRINT LPAREN RPAREN {
        printf("\n");
    }
    ;

assignment:
    IDENTIFIER ASSIGN expression {
        set_var_value($1, $3.value, $3.is_boolean);
        free($1);  // Liberar la memoria del identificador
    }
    ;

expression:
    NUMBER {
        $$.value = $1;
        $$.is_boolean = 0;
    }
    | BOOLEAN {
        $$.value = $1;
        $$.is_boolean = 1;
    }
    | IDENTIFIER {
        variable var = get_var($1);
        $$.value = var.value;
        $$.is_boolean = var.is_boolean;
    }
    | expression PLUS expression {
        $$.value = $1.value + $3.value;
        $$.is_boolean = 0;
    }
    | expression MINUS expression {
        $$.value = $1.value - $3.value;
        $$.is_boolean = 0;
    }
    | expression MULT expression {
        $$.value = $1.value * $3.value;
        $$.is_boolean = 0;
    }
    | expression DIV expression {
        $$.value = $1.value / $3.value;
        $$.is_boolean = 0;
    }
    | LPAREN expression RPAREN {
        $$.value = $2.value;
        $$.is_boolean = $2.is_boolean;
    }
    | expression AND expression {
        $$.value = $1.value && $3.value;
        $$.is_boolean = 1;
    }
    | expression OR expression {
        $$.value = $1.value || $3.value;
        $$.is_boolean = 1;
    }
    | NOT expression {
        $$.value = !$2.value;
        $$.is_boolean = 1;
    }
    ;

%%

void yyerror(const char *s) {
    fprintf(stderr, "Error: %s\n", s);
}

int main() {
    yyparse();
    return 0;
}

variable get_var(const char *name) {
    for (int i = 0; i < num_vars; i++) {
        if (strcmp(vars[i].name, name) == 0) {
            return vars[i];
        }
    }
    fprintf(stderr, "Error: Variable '%s' not found\n", name);
    exit(EXIT_FAILURE);
}

void set_var_value(const char *name, int value, int is_boolean) {
    for (int i = 0; i < num_vars; i++) {
        if (strcmp(vars[i].name, name) == 0) {
            vars[i].value = value;
            vars[i].is_boolean = is_boolean;
            return;
        }
    }
    if (num_vars < MAX_VARS) {
        vars[num_vars].name = strdup(name);
        vars[num_vars].value = value;
        vars[num_vars].is_boolean = is_boolean;
        num_vars++;
    } else {
        fprintf(stderr, "Error: Too many variables\n");
        exit(EXIT_FAILURE);
    }
}
