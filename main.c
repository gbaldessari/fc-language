#include <stdio.h>
#include <string.h>
#include "parser.tab.h"

// Prototipo de la función yyparse
extern int yyparse(void);

int main(void) {
    printf("Ingrese el código (termine con una línea vacía):\n");

    if (!yyparse()) {
        printf("Parsing completed successfully.\n");
    } else {
        printf("Parsing failed.\n");
    }

    return 0;
}
