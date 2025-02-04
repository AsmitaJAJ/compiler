#include <stdio.h>
#include <stdlib.h>
#include <string.h>

#define TABLE_SIZE 100

typedef struct Symbol {
    char name[50];
    char type[50];

    struct Symbol* next;

} Symbol;

Symbol* symbolTable[TABLE_SIZE];

unsigned int hash(const char* key) {
    unsigned int hash = 0;
    while (*key) {
        hash = (hash * 31) + *key++;  //31 is a prime number, helps better distribution 
    }
    return hash % TABLE_SIZE;
}

void insert_symbol(const char* name) {
    unsigned int index = hash(name);
    
    Symbol* newSymbol = (Symbol*)malloc(sizeof(Symbol));
    strcpy(newSymbol->name, name);
    newSymbol->next = symbolTable[index];
    symbolTable[index] = newSymbol;
}

int lookup_symbol(const char* name) {
    unsigned int index = hash(name);
    Symbol* entry = symbolTable[index];

    while (entry) {
        if (strcmp(entry->name, name) == 0) {
            return 1; // Found
        }
        entry = entry->next;
    }
    return 0; // Not found
}
