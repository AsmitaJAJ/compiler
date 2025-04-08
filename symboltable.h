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

typedef struct SemError {
    char sem_error_message[50];
    int linenumber;
    char error_var[50];
    struct SemError* next;
} SemError;

void insert_symbol(const char* name, const char* type, int linenumber);
void write_semantic_errors(const char* sem_error_message, int linecount, const char* error_var);

Symbol* lookup_symbol(const char* name);

#endif // SYMBOLTABLE_H
