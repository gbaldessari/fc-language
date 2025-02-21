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
    float float_value;
    int is_float;
} variable;


#define MAX_VARS 100
variable vars[MAX_VARS];
int num_vars = 0;

variable get_var(const char *name);
void set_var_value(const char *name, int value, int is_boolean, const char *str_value, int is_string, float float_value, int is_float);


void print_value(int value, int is_boolean, const char *str_value, int is_string, float float_value, int is_float) {
    if (is_string) {
        printf("%s\n", str_value);
    } else if (is_boolean) {
        printf(value ? "true\n" : "false\n");
    } else if (is_float) {
        printf("%f\n", float_value);
    } else {
        printf("%d\n", value);
    }
}

int execute_block = 1;
int last_condition = 0;
%}

%union {
    int num;
    float flt;
    char *str;
    struct {
        int value;
        int is_boolean;
        char *str_value;
        int is_string;
        float float_value;
        int is_float;
    } exp;
}

%token <str> IDENTIFIER
%token <str> STRING
%token <num> NUMBER BOOLEAN
%token <flt> FLOAT
%token PLUS MINUS MULT DIV
%token LPAREN RPAREN SEMICOLON LBRACE RBRACE
%token PRINT IF ELSE WHILE
%nonassoc ELSE
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
    | while_statement
    ;

print_statement:
    PRINT LPAREN expression RPAREN {
        if (execute_block) {
            print_value($3.value, $3.is_boolean, $3.str_value, $3.is_string, $3.float_value, $3.is_float);
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
            set_var_value($1, $3.value, $3.is_boolean, $3.str_value, $3.is_string, $3.float_value, $3.is_float);
            free($1);
            if ($3.str_value) {
                free($3.str_value);
            }
        }
    }
    ;

if_statement:
    IF LPAREN expression RPAREN LBRACE {
        last_condition = $3.value;
        execute_block = last_condition;
    } lines RBRACE {
        execute_block = 1;
    }
    if_else_statement
    ;

if_else_statement:
    | ELSE LBRACE {
        execute_block = !last_condition;
    } lines RBRACE {
        execute_block = 1;
    }
    ;

while_statement:
    WHILE LPAREN expression RPAREN LBRACE lines RBRACE 
    ;

expression:
    NUMBER {
        $$.value = $1;
        $$.is_boolean = 0;
        $$.is_string = 0;
        $$.is_float = 0;
    }
    | FLOAT {
        $$.float_value = $1;
        $$.is_float = 1;
        $$.is_boolean = 0;
        $$.is_string = 0;
    }
    | BOOLEAN {
        $$.value = $1;
        $$.is_boolean = 1;
        $$.is_string = 0;
        $$.is_float = 0;
    }
    | STRING {
        $$.str_value = strdup($1);
        $$.is_string = 1;
        $$.is_boolean = 0;
        $$.is_float = 0;
    }
    | IDENTIFIER {
        variable var = get_var($1);
        $$.value = var.value;
        $$.is_boolean = var.is_boolean;
        $$.str_value = var.str_value ? strdup(var.str_value) : NULL;
        $$.is_string = var.is_string;
        $$.float_value = var.float_value;
        $$.is_float = var.is_float;
        free($1);
    }
    | expression PLUS expression {
        if ($1.is_float || $3.is_float) {
            $$.float_value = ($1.is_float ? $1.float_value : $1.value) +
                             ($3.is_float ? $3.float_value : $3.value);
            $$.is_float = 1;
            $$.is_string = 0;
            $$.is_boolean = 0;
        } else if ($1.is_string || $3.is_string) {
            char *combined = malloc(strlen($1.str_value ? $1.str_value : "") + strlen($3.str_value ? $3.str_value : "") + 1);
            strcpy(combined, $1.str_value ? $1.str_value : "");
            strcat(combined, $3.str_value ? $3.str_value : "");
            $$.str_value = combined;
            $$.is_string = 1;
            $$.is_boolean = 0;
            $$.is_float = 0;
        } else {
            $$.value = $1.value + $3.value;
            $$.is_string = 0;
            $$.is_boolean = 0;
            $$.is_float = 0;
        }
    }
    | expression MINUS expression {
        if ($1.is_float || $3.is_float) {
            $$.float_value = ($1.is_float ? $1.float_value : $1.value) -
                             ($3.is_float ? $3.float_value : $3.value);
            $$.is_float = 1;
            $$.is_string = 0;
            $$.is_boolean = 0;
        } else {
            $$.value = $1.value - $3.value;
            $$.is_string = 0;
            $$.is_boolean = 0;
            $$.is_float = 0;
        }
    }
    | expression MULT expression {
        if ($1.is_float || $3.is_float) {
            $$.float_value = ($1.is_float ? $1.float_value : $1.value) *
                             ($3.is_float ? $3.float_value : $3.value);
            $$.is_float = 1;
            $$.is_string = 0;
            $$.is_boolean = 0;
        } else {
            $$.value = $1.value * $3.value;
            $$.is_string = 0;
            $$.is_boolean = 0;
            $$.is_float = 0;
        }
    }
    | expression DIV expression {
        if (($3.is_float && $3.float_value == 0.0) || (!$3.is_float && $3.value == 0)) {
            yyerror("Error: División por cero");
            YYABORT;
        }
        if ($1.is_float || $3.is_float) {
            $$.float_value = ($1.is_float ? $1.float_value : $1.value) /
                             ($3.is_float ? $3.float_value : $3.value);
            $$.is_float = 1;
            $$.is_string = 0;
            $$.is_boolean = 0;
        } else {
            $$.value = $1.value / $3.value;
            $$.is_string = 0;
            $$.is_boolean = 0;
            $$.is_float = 0;
        }
    }
    | LPAREN expression RPAREN {
        $$.value = $2.value;
        $$.is_boolean = $2.is_boolean;
        $$.str_value = $2.str_value;
        $$.is_string = $2.is_string;
        $$.float_value = $2.float_value;
        $$.is_float = $2.is_float;
    }
    | expression AND expression {
        $$.value = $1.value && $3.value;
        $$.is_boolean = 1;
        $$.is_string = 0;
        $$.is_float = 0;
    }
    | expression OR expression {
        $$.value = $1.value || $3.value;
        $$.is_boolean = 1;
        $$.is_string = 0;
        $$.is_float = 0;
    }
    | NOT expression {
        $$.value = !$2.value;
        $$.is_boolean = 1;
        $$.is_string = 0;
        $$.is_float = 0;
    }
    | expression EQ expression {
        if ($1.is_float || $3.is_float) {
            $$.value = ($1.is_float ? $1.float_value : $1.value) == ($3.is_float ? $3.float_value : $3.value);
            $$.is_boolean = 1;
            $$.is_string = 0;
            $$.is_float = 0;
        } else {
            $$.value = $1.value == $3.value;
            $$.is_boolean = 1;
            $$.is_string = 0;
            $$.is_float = 0;
        }
    }
    | expression NE expression {
        if ($1.is_float || $3.is_float) {
            $$.value = ($1.is_float ? $1.float_value : $1.value) != ($3.is_float ? $3.float_value : $3.value);
            $$.is_boolean = 1;
            $$.is_string = 0;
            $$.is_float = 0;
        } else {
            $$.value = $1.value != $3.value;
            $$.is_boolean = 1;
            $$.is_string = 0;
            $$.is_float = 0;
        }
    }
    | expression LT expression {
        if ($1.is_float || $3.is_float) {
            $$.value = ($1.is_float ? $1.float_value : $1.value) < ($3.is_float ? $3.float_value : $3.value);
            $$.is_boolean = 1;
            $$.is_string = 0;
            $$.is_float = 0;
        } else {
            $$.value = $1.value < $3.value;
            $$.is_boolean = 1;
            $$.is_string = 0;
            $$.is_float = 0;
        }
    }
    | expression LE expression {
        if ($1.is_float || $3.is_float) {
            $$.value = ($1.is_float ? $1.float_value : $1.value) <= ($3.is_float ? $3.float_value : $3.value);
            $$.is_boolean = 1;
            $$.is_string = 0;
            $$.is_float = 0;
        } else {
            $$.value = $1.value <= $3.value;
            $$.is_boolean = 1;
            $$.is_string = 0;
            $$.is_float = 0;
        }
    }
    | expression GT expression {
        if ($1.is_float || $3.is_float) {
            $$.value = ($1.is_float ? $1.float_value : $1.value) > ($3.is_float ? $3.float_value : $3.value);
            $$.is_boolean = 1;
            $$.is_string = 0;
            $$.is_float = 0;
        } else {
            $$.value = $1.value > $3.value;
            $$.is_boolean = 1;
            $$.is_string = 0;
            $$.is_float = 0;
        }
    }
    | expression GE expression {
        if ($1.is_float || $3.is_float) {
            $$.value = ($1.is_float ? $1.float_value : $1.value) >= ($3.is_float ? $3.float_value : $3.value);
            $$.is_boolean = 1;
            $$.is_string = 0;
            $$.is_float = 0;
        } else {
            $$.value = $1.value >= $3.value;
            $$.is_boolean = 1;
            $$.is_string = 0;
            $$.is_float = 0;
        }
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

void set_var_value(const char *name, int value, int is_boolean, const char *str_value, int is_string, float float_value, int is_float) {
    for (int i = 0; i < num_vars; i++) {
        if (strcmp(vars[i].name, name) == 0) {
            vars[i].value = value;
            vars[i].is_boolean = is_boolean;
            vars[i].is_float = is_float;
            vars[i].float_value = float_value;
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
        vars[num_vars].is_float = is_float;
        vars[num_vars].float_value = float_value;
        vars[num_vars].str_value = str_value ? strdup(str_value) : NULL;
        vars[num_vars].is_string = is_string;
        num_vars++;
    } else {
        fprintf(stderr, "Error: Too many variables\n");
        exit(EXIT_FAILURE);
    }
}
