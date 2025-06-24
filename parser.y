%{
#include "parser.tab.h"
#include <stdio.h>
#include <stdlib.h>
#include <string.h>

typedef enum { 
    AST_PROGRAM, AST_LINES, AST_PRINT, AST_ASSIGN, AST_IF, AST_IFELSE, AST_WHILE, AST_EXPR 
} ASTNodeType;

typedef struct ASTNode {
    ASTNodeType type;
    struct ASTNode *left;
    struct ASTNode *right;
    struct ASTNode *cond;
    struct ASTNode *then_block;
    struct ASTNode *else_block;
    struct ASTNode *body;
    char *id;
    struct {
        int value;
        int is_boolean;
        char *str_value;
        int is_string;
        float float_value;
        int is_float;
    } exp;
} ASTNode;

ASTNode *ast_program(ASTNode *lines);
ASTNode *ast_lines(ASTNode *left, ASTNode *right);
ASTNode *ast_print(ASTNode *expr);
ASTNode *ast_assign(char *id, ASTNode *expr);
ASTNode *ast_if(ASTNode *cond, ASTNode *then_block, ASTNode *else_block);
ASTNode *ast_while(ASTNode *cond, ASTNode *body);
ASTNode *ast_expr(int value, int is_boolean, char *str_value, int is_string, float float_value, int is_float);
void eval(ASTNode *node);

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
    struct ASTNode *node;
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
%type <node> expression
%type <node> lines
%type <node> line
%type <node> print_statement
%type <node> assignment
%type <node> if_statement
%type <node> if_else_statement
%type <node> while_statement

%left OR
%left AND
%right NOT
%left PLUS MINUS
%left MULT DIV
%left EQ NE
%left LT GT LE GE

%%

program:
    lines { eval(ast_program($1)); }
    ;

lines:
    line { $$ = $1; }
    | lines line { $$ = ast_lines($1, $2); }
    ;

line:
    print_statement SEMICOLON { $$ = $1; }
    | assignment SEMICOLON { $$ = $1; }
    | if_statement { $$ = $1; }
    | while_statement { $$ = $1; }
    ;

print_statement:
    PRINT LPAREN expression RPAREN { $$ = ast_print($3); }
    | PRINT LPAREN RPAREN { $$ = ast_print(NULL); }
    ;

assignment:
    IDENTIFIER ASSIGN expression { $$ = ast_assign($1, $3); }
    ;

if_statement:
    IF LPAREN expression RPAREN LBRACE lines RBRACE if_else_statement
    {
        $$ = ast_if(ast_expr($3->exp.value, $3->exp.is_boolean, $3->exp.str_value, $3->exp.is_string, $3->exp.float_value, $3->exp.is_float), $6, $8);
    }
    ;

if_else_statement:
    /* vacío */ { $$ = NULL; }
    | ELSE LBRACE lines RBRACE { $$ = $3; }
    ;

while_statement:
    WHILE LPAREN expression RPAREN LBRACE lines RBRACE
    {
        $$ = ast_while(ast_expr($3->exp.value, $3->exp.is_boolean, $3->exp.str_value, $3->exp.is_string, $3->exp.float_value, $3->exp.is_float), $6);
    }
    ;

expression:
    NUMBER { $$ = ast_expr($1, 0, NULL, 0, 0.0, 0); }
    | FLOAT { $$ = ast_expr(0, 0, NULL, 0, $1, 1); }
    | BOOLEAN { $$ = ast_expr($1, 1, NULL, 0, 0.0, 0); }
    | STRING { $$ = ast_expr(0, 0, $1, 1, 0.0, 0); }
    | IDENTIFIER {
        variable var = get_var($1);
        $$ = ast_expr(var.value, var.is_boolean, var.str_value ? strdup(var.str_value) : NULL, var.is_string, var.float_value, var.is_float);
        free($1);
    }
    | expression PLUS expression {
        if ($1->exp.is_float || $3->exp.is_float) {
            $$ = ast_expr(0, 0, NULL, 0, 
                ($1->exp.is_float ? $1->exp.float_value : $1->exp.value) +
                ($3->exp.is_float ? $3->exp.float_value : $3->exp.value), 1);
        } else if ($1->exp.is_string || $3->exp.is_string) {
            char *s1 = $1->exp.str_value ? $1->exp.str_value : "";
            char *s2 = $3->exp.str_value ? $3->exp.str_value : "";
            char *combined = malloc(strlen(s1) + strlen(s2) + 1);
            strcpy(combined, s1);
            strcat(combined, s2);
            $$ = ast_expr(0, 0, combined, 1, 0.0, 0);
        } else {
            $$ = ast_expr($1->exp.value + $3->exp.value, 0, NULL, 0, 0.0, 0);
        }
    }
    | expression MINUS expression {
        if ($1->exp.is_float || $3->exp.is_float) {
            $$ = ast_expr(0, 0, NULL, 0, 
                ($1->exp.is_float ? $1->exp.float_value : $1->exp.value) -
                ($3->exp.is_float ? $3->exp.float_value : $3->exp.value), 1);
        } else {
            $$ = ast_expr($1->exp.value - $3->exp.value, 0, NULL, 0, 0.0, 0);
        }
    }
    | expression MULT expression {
        if ($1->exp.is_float || $3->exp.is_float) {
            $$ = ast_expr(0, 0, NULL, 0, 
                ($1->exp.is_float ? $1->exp.float_value : $1->exp.value) *
                ($3->exp.is_float ? $3->exp.float_value : $3->exp.value), 1);
        } else {
            $$ = ast_expr($1->exp.value * $3->exp.value, 0, NULL, 0, 0.0, 0);
        }
    }
    | expression DIV expression {
        float divisor = $3->exp.is_float ? $3->exp.float_value : $3->exp.value;
        if (divisor == 0) {
            yyerror("Error: División por cero");
            YYABORT;
        }
        if ($1->exp.is_float || $3->exp.is_float) {
            $$ = ast_expr(0, 0, NULL, 0, 
                ($1->exp.is_float ? $1->exp.float_value : $1->exp.value) /
                divisor, 1);
        } else {
            $$ = ast_expr($1->exp.value / $3->exp.value, 0, NULL, 0, 0.0, 0);
        }
    }
    | LPAREN expression RPAREN { $$ = $2; }
    | expression AND expression {
        $$ = ast_expr($1->exp.value && $3->exp.value, 1, NULL, 0, 0.0, 0);
    }
    | expression OR expression {
        $$ = ast_expr($1->exp.value || $3->exp.value, 1, NULL, 0, 0.0, 0);
    }
    | NOT expression {
        $$ = ast_expr(!$2->exp.value, 1, NULL, 0, 0.0, 0);
    }
    | expression EQ expression {
        int result;
        if ($1->exp.is_float || $3->exp.is_float) {
            result = (($1->exp.is_float ? $1->exp.float_value : $1->exp.value) == 
                      ($3->exp.is_float ? $3->exp.float_value : $3->exp.value));
        } else {
            result = ($1->exp.value == $3->exp.value);
        }
        $$ = ast_expr(result, 1, NULL, 0, 0.0, 0);
    }
    | expression NE expression {
        int result;
        if ($1->exp.is_float || $3->exp.is_float) {
            result = (($1->exp.is_float ? $1->exp.float_value : $1->exp.value) != 
                      ($3->exp.is_float ? $3->exp.float_value : $3->exp.value));
        } else {
            result = ($1->exp.value != $3->exp.value);
        }
        $$ = ast_expr(result, 1, NULL, 0, 0.0, 0);
    }
    | expression LT expression {
        int result;
        if ($1->exp.is_float || $3->exp.is_float) {
            result = (($1->exp.is_float ? $1->exp.float_value : $1->exp.value) < 
                      ($3->exp.is_float ? $3->exp.float_value : $3->exp.value));
        } else {
            result = ($1->exp.value < $3->exp.value);
        }
        $$ = ast_expr(result, 1, NULL, 0, 0.0, 0);
    }
    | expression LE expression {
        int result;
        if ($1->exp.is_float || $3->exp.is_float) {
            result = (($1->exp.is_float ? $1->exp.float_value : $1->exp.value) <= 
                      ($3->exp.is_float ? $3->exp.float_value : $3->exp.value));
        } else {
            result = ($1->exp.value <= $3->exp.value);
        }
        $$ = ast_expr(result, 1, NULL, 0, 0.0, 0);
    }
    | expression GT expression {
        int result;
        if ($1->exp.is_float || $3->exp.is_float) {
            result = (($1->exp.is_float ? $1->exp.float_value : $1->exp.value) > 
                      ($3->exp.is_float ? $3->exp.float_value : $3->exp.value));
        } else {
            result = ($1->exp.value > $3->exp.value);
        }
        $$ = ast_expr(result, 1, NULL, 0, 0.0, 0);
    }
    | expression GE expression {
        int result;
        if ($1->exp.is_float || $3->exp.is_float) {
            result = (($1->exp.is_float ? $1->exp.float_value : $1->exp.value) >= 
                      ($3->exp.is_float ? $3->exp.float_value : $3->exp.value));
        } else {
            result = ($1->exp.value >= $3->exp.value);
        }
        $$ = ast_expr(result, 1, NULL, 0, 0.0, 0);
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

ASTNode *ast_program(ASTNode *lines) {
    ASTNode *node = malloc(sizeof(ASTNode));
    node->type = AST_PROGRAM;
    node->left = lines;
    return node;
}

ASTNode *ast_lines(ASTNode *left, ASTNode *right) {
    ASTNode *node = malloc(sizeof(ASTNode));
    node->type = AST_LINES;
    node->left = left;
    node->right = right;
    return node;
}

ASTNode *ast_print(ASTNode *expr) {
    ASTNode *node = malloc(sizeof(ASTNode));
    node->type = AST_PRINT;
    node->left = expr;
    return node;
}

ASTNode *ast_assign(char *id, ASTNode *expr) {
    ASTNode *node = malloc(sizeof(ASTNode));
    node->type = AST_ASSIGN;
    node->id = id;
    node->left = expr;
    return node;
}

ASTNode *ast_if(ASTNode *cond, ASTNode *then_block, ASTNode *else_block) {
    ASTNode *node = malloc(sizeof(ASTNode));
    node->type = AST_IF;
    node->cond = cond;
    node->then_block = then_block;
    node->else_block = else_block;
    return node;
}

ASTNode *ast_while(ASTNode *cond, ASTNode *body) {
    ASTNode *node = malloc(sizeof(ASTNode));
    node->type = AST_WHILE;
    node->cond = cond;
    node->body = body;
    return node;
}

ASTNode *ast_expr(int value, int is_boolean, char *str_value, int is_string, float float_value, int is_float) {
    ASTNode *node = malloc(sizeof(ASTNode));
    node->type = AST_EXPR;
    node->exp.value = value;
    node->exp.is_boolean = is_boolean;
    node->exp.str_value = str_value ? strdup(str_value) : NULL;
    node->exp.is_string = is_string;
    node->exp.float_value = float_value;
    node->exp.is_float = is_float;
    return node;
}

// Evaluador del AST
void eval(ASTNode *node) {
    if (!node) return;
    switch (node->type) {
        case AST_PROGRAM:
            eval(node->left);
            break;
        case AST_LINES:
            eval(node->left);
            eval(node->right);
            break;
        case AST_PRINT:
            if (node->left)
                print_value(node->left->exp.value, node->left->exp.is_boolean, node->left->exp.str_value, node->left->exp.is_string, node->left->exp.float_value, node->left->exp.is_float);
            else
                printf("\n");
            break;
        case AST_ASSIGN:
            set_var_value(node->id, node->left->exp.value, node->left->exp.is_boolean, node->left->exp.str_value, node->left->exp.is_string, node->left->exp.float_value, node->left->exp.is_float);
            break;
        case AST_IF:
            if (node->cond->exp.value)
                eval(node->then_block);
            else if (node->else_block)
                eval(node->else_block);
            break;
        case AST_WHILE:
            while (node->cond->exp.value) {
                eval(node->body);
                // Re-evaluar la condición (deberías reconstruir el nodo de condición si depende de variables)
            }
            break;
        case AST_EXPR:
            // Nada que hacer
            break;
    }
}
