#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include "symboltable.h"
#define TABLE_SIZE 100

extern int linecount;
extern int semantic_error;

Symbol* lookup_symbol(const char* name);
char keyword[20][10] = {"function", "program", "int", "var", "array", "of", "begin", "end", "if", "then", "else", "for", "while", "do", "for", "read", "write", "procedure", "printf", "include"};

Symbol* symbolTable[TABLE_SIZE];

unsigned int hash(const char* key) {
    unsigned int hash = 0;
    while (*key) {
        hash = (hash * 31) + *key++;  //31 is a prime number, helps better distribution
    }
    return hash % TABLE_SIZE;
}

void insert_symbol(const char* name,const char* type, int linenumber) {
    unsigned int index = hash(name);
        // Check duplicate declartion of variables
        if (lookup_symbol(name)) {
            printf("====Error: Line Number: %d, Duplicate declaration of identifier %s====\n", linecount, name);
            semantic_error++;
            return;
        }
        // Check if variable name is a keyword

        for(int i=0; i<20; i++) {
            if(strcmp(keyword[i], name) == 0) {
                printf("====Error: Line Number: %d, Variable name is a keyword %s====\n", linecount, name);
                semantic_error++;
                return;
            }
        }

    Symbol* newSymbol = (Symbol*)malloc(sizeof(Symbol));
    strcpy(newSymbol->name, name);
    strcpy(newSymbol->type, type);
    newSymbol->linenumber = linecount;
    newSymbol->next = symbolTable[index];
    symbolTable[index] = newSymbol;
}

Symbol* lookup_symbol(const char* name) {
    unsigned int index = hash(name);
    Symbol* entry = symbolTable[index];

    while (entry) {
        if (strcmp(entry->name, name) == 0) {
            return entry; // Found
        }
        entry = entry->next;
    }
    return NULL; // Not found
}

void print_symbol_table() {
    printf("\nSYMBOL TABLE:\n");
    printf("----------------------------\n");
    printf("| %-15s | %-10s | %-10s |\n", "Identifier", "Type", "LineNumber");

    printf("-----------------------------------------\n");

    for (int i = 0; i < TABLE_SIZE; i++) {
        Symbol* entry = symbolTable[i];
        while (entry) {
            printf("| %-15s | %-10s |%d\n", entry->name, entry->type, entry->linenumber);
            entry = entry->next;
        }
    }
    printf("-----------------------------------------\n");
}
