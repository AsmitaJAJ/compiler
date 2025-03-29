void yyerror(const char *s);

int yyparse();
int yylex();
int yywrap();

#ifndef SYMBOLTABLE_H //if not defined
#define SYMBOLTABLE_H
typedef struct Symbol {
    char name[50];
    char type[50];
    int linenumber;
    struct Symbol* next;

} Symbol;
void insert_symbol(const char* name, const char* type, int linenumber);
Symbol* lookup_symbol(const char* name);

#endif // SYMBOLTABLE_H
