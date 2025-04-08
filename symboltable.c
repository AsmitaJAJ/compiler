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
SemError* semerrorTable[TABLE_SIZE];

unsigned int hash(const char* key) {
    unsigned int hash = 0;
    while (*key) {
        hash = (hash * 31) + *key++;  //31 is a prime number, helps better distribution
    }
    return hash % TABLE_SIZE;
}

void write_semantic_errors(const char* sem_error_message, int linecount, const char* error_var) {
    printf ("In write sem errors");
    unsigned int index = hash(sem_error_message);

    SemError* newSemError = (SemError*)malloc(sizeof(SemError));
    strcpy(newSemError->sem_error_message, sem_error_message);
    strcpy(newSemError->error_var, error_var);
    newSemError->linenumber = linecount;
    newSemError->next = semerrorTable[index];
    semerrorTable[index] = newSemError;
}


void insert_symbol(const char* name,const char* type, int linenumber) {
    unsigned int index = hash(name);
        // Check duplicate declartion of variables
        if (lookup_symbol(name)) {
            printf("====Error: Line Number: %d, Duplicate declaration of identifier %s====\n", linecount, name);
            semantic_error++;
            write_semantic_errors("Duplicate declaration of identifier ", linecount, name);
            return;
        }
        // Check if variable name is a keyword

        for(int i=0; i<20; i++) {
            if(strcmp(keyword[i], name) == 0) {
                printf("====Error: Line Number: %d, Variable name is a keyword %s====\n", linecount, name);
                write_semantic_errors("Variable name is a keyword ", linecount, name);
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
    printf("-----------------------------------------------------\n");
    printf("| %-15s | %-10s | %-10s |\n", "Identifier", "Variable", "LineNumber");
    printf("-----------------------------------------------------\n");

    for (int i = 0; i < TABLE_SIZE; i++) {
        Symbol* entry = symbolTable[i];
        while (entry) {
            printf("| %-15s | %-10s | %d\n", entry->name, entry->type, entry->linenumber);
            entry = entry->next;
        }
    }
    printf("-----------------------------------------------------\n");
}

void print_semantic_errors() {
    FILE *SEMERRORS_FILE;

    // Delete the SemanticErrors file if it exists
    if (remove("SemErrors") == 0) {
        printf("SemErrors File deleted successfully.\n");
    } else {
        printf("SemErrors File does not exist or could not be deleted.\n");
    }

    SEMERRORS_FILE = fopen("SemErrors", "a");
    if (SEMERRORS_FILE == NULL) {
        perror("Symboltable - Error opening file - SemErrors");
        exit(1);
    }

    printf("\nSemantic Errors TABLE:\n");
    printf("-----------------------------------------------------\n");
    printf("| %-20s | %-10s | %-10s |\n", "Error MEssage", "Error Variable", "LineNumber");
    for (int i = 0; i < TABLE_SIZE; i++) {
        SemError* entry = semerrorTable[i];
        while (entry) {
            printf("| %-15s | %-10s | %d\n", entry->sem_error_message, entry->error_var, entry->linenumber);
            //printf("LN %s, Error: %s, Variable Name: %s\n", entry->linenumber, entry->sem_error_message, entry->error_var);
            entry = entry->next;
        }
    }
    printf("-----------------------------------------------------\n");

    //Add the Semantic Error Details to SemErrors file
    fprintf(SEMERRORS_FILE, "\n--- Semantic Errors ----\n");
    fprintf(SEMERRORS_FILE, "Number of Semantic Errors : %d\n", semantic_error);

    for (int i = 0; i < TABLE_SIZE; i++) {
        SemError* entry = semerrorTable[i];
        while (entry) {
            fprintf(SEMERRORS_FILE, "LN %d, Error: %s, Variable Name: %s\n", entry->linenumber, entry->sem_error_message, entry->error_var );
            entry = entry->next;
        }
    }
    fclose(SEMERRORS_FILE);
}
