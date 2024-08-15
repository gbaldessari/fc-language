%{
#include "parser.tab.h"
#include <stdio.h>
#include <stdlib.h>
#include <string.h>

void yyerror(const char *s);
int yylex();

typedef struct {
    char *name;
    int value;
    int is_boolean;
    char *str_value;
    int is_string;
} variable;


#define MAX_VARS 100
variable vars[MAX_VARS];
int num_vars = 0;

variable get_var(const char *name);
void set_var_value(const char *name, int value, int is_boolean, const char *str_value, int is_string);


void print_value(int value, int is_boolean, const char *str_value, int is_string) {
    if (is_string) {
        printf("%s\n", str_value);
    } else if (is_boolean) {
        printf(value ? "true\n" : "false\n");
    } else {
        printf("%d\n", value);
    }
}


int execute_block;
%}


%union {
    int num;
    char *str;
    struct {
        int value;
        int is_boolean;
        char *str_value;
        int is_string;
    } exp;
}

%token <num> NUMBER BOOLEAN
%token PLUS MINUS MULT DIV
%token LPAREN RPAREN SEMICOLON LBRACE RBRACE
%token PRINT IF
%token <str> IDENTIFIER
%token <str> STRING
%token AND OR NOT
%token ASSIGN
%token EQ LE GE LT GT NE
%type <exp> expression

%left OR
%left AND
%right NOT
%left PLUS MINUS
%left MULT DIV
%left EQ NE
%left LT GT LE GE

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
    | if_statement
    ;

print_statement:
    PRINT LPAREN expression RPAREN {
        if (execute_block) {
            print_value($3.value, $3.is_boolean, $3.str_value, $3.is_string);
        }
        if ($3.str_value) {
            free($3.str_value);
        }
    }
    | PRINT LPAREN RPAREN {
        if (execute_block) {
            printf("\n");
        }
    }
    ;

assignment:
    IDENTIFIER ASSIGN expression {
        if (execute_block) {
            set_var_value($1, $3.value, $3.is_boolean, $3.str_value, $3.is_string);
            free($1);
            if ($3.str_value) {
                free($3.str_value);
            }
        }
    }
    ;

if_statement:
    IF LPAREN expression RPAREN LBRACE {
        if ($3.value) {
            execute_block = 1;
        } else {
            execute_block = 0;
        }
    } lines RBRACE {
        execute_block = 1; // Restaurar ejecución del bloque después del if
    }
    ;

expression:
    NUMBER {
        $$.value = $1;
        $$.is_boolean = 0;
        $$.is_string = 0;
    }
    | BOOLEAN {
        $$.value = $1;
        $$.is_boolean = 1;
        $$.is_string = 0;
    }
    | STRING {
        $$.str_value = strdup($1);
        $$.is_string = 1;
        $$.is_boolean = 0;
    }
    | IDENTIFIER {
        variable var = get_var($1);
        $$.value = var.value;
        $$.is_boolean = var.is_boolean;
        $$.str_value = var.str_value ? strdup(var.str_value) : NULL;
        $$.is_string = var.is_string;
        free($1);
    }
    | expression PLUS expression {
        if ($1.is_string || $3.is_string) {
            char *combined = malloc(strlen($1.str_value ? $1.str_value : "") + strlen($3.str_value ? $3.str_value : "") + 1);
            strcpy(combined, $1.str_value ? $1.str_value : "");
            strcat(combined, $3.str_value ? $3.str_value : "");
            $$.str_value = combined;
            $$.is_string = 1;
            $$.is_boolean = 0;
        } else {
            $$.value = $1.value + $3.value;
            $$.is_string = 0;
            $$.is_boolean = 0;
        }
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
        if ($3.value == 0) {
            yyerror("Error: División por cero");
            YYABORT;
        }
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
    | expression EQ expression {
        $$.value = $1.value == $3.value;
        $$.is_boolean = 1;
    }
    | expression NE expression {
        $$.value = $1.value != $3.value;
        $$.is_boolean = 1;
    }
    | expression LT expression {
        $$.value = $1.value < $3.value;
        $$.is_boolean = 1;
    }
    | expression LE expression {
        $$.value = $1.value <= $3.value;
        $$.is_boolean = 1;
    }
    | expression GT expression {
        $$.value = $1.value > $3.value;
        $$.is_boolean = 1;
    }
    | expression GE expression {
        $$.value = $1.value >= $3.value;
        $$.is_boolean = 1;
    }
    ;

%%

void yyerror(const char *s) {
    fprintf(stderr, "Error: %s\n", s);
}

int main() {
    printf(" --------------------------------------\n");
    printf("|   Bienvenido al Papu Compilador     |\n");
    printf("| Hecho por los Papus para los Papus  |\n");
    printf(" --------------------------------------\n");

    char filename[1024];
    printf("Ingrese el nombre del archivo de entrada (ejemplo: input.papu): ");
    fgets(filename, sizeof(filename), stdin);
    filename[strcspn(filename, "\n")] = 0;

    FILE *file = fopen(filename, "r");
    if (!file) {
        perror("Error al abrir el archivo");
        return 1;
    }

    extern FILE *yyin;
    yyin = file;

    execute_block = 1; // Inicialmente permitir la ejecución del bloque

    if (!yyparse()) {
        printf("Parsing completed successfully.\n");
    } else {
        printf("Parsing failed.\n");
    }

    fclose(file);

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

void set_var_value(const char *name, int value, int is_boolean, const char *str_value, int is_string) {
    for (int i = 0; i < num_vars; i++) {
        if (strcmp(vars[i].name, name) == 0) {
            vars[i].value = value;
            vars[i].is_boolean = is_boolean;
            if (vars[i].str_value) {
                free(vars[i].str_value);
            }
            vars[i].str_value = str_value ? strdup(str_value) : NULL;
            vars[i].is_string = is_string;
            return;
        }
    }
    if (num_vars < MAX_VARS) {
        vars[num_vars].name = strdup(name);
        vars[num_vars].value = value;
        vars[num_vars].is_boolean = is_boolean;
        vars[num_vars].str_value = str_value ? strdup(str_value) : NULL;
        vars[num_vars].is_string = is_string;
        num_vars++;
    } else {
        fprintf(stderr, "Error: Too many variables\n");
        exit(EXIT_FAILURE);
    }
}
