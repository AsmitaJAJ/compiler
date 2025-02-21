#ifndef SYMBOLTABLE_H //if not defined
#define SYMBOLTABLE_H
typedef struct Symbol {
    char name[50];
    char type[50];

    struct Symbol* next;

} Symbol;
void insert_symbol(const char* name, const char* type);
Symbol* lookup_symbol(const char* name);

#endif // SYMBOLTABLE_H