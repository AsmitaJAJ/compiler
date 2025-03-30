#ifndef ICG_H
#define ICG_H

#include <stdio.h>
#include <stdlib.h>
#include <string.h>

// Define IR instruction structure
typedef struct {
    char *op;     // Operator (e.g., '=', 'if', 'goto')
    char *arg1;   // Operand 1
    char *arg2;   // Operand 2 (if any)
    char *result; // Result or label
} IRInstruction;

// IR List structure
typedef struct {
    IRInstruction **instructions;
    int size;
    int capacity;
} IRList;

// Function prototypes
IRList* createIRList();
void addInstruction(IRList *irList, char *op, char *arg1, char *arg2, char *result);
void printIRList(IRList *irList);

#endif // ICG_H
