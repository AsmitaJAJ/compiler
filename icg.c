#include "icg.h"

// Function to create an IR list
IRList* createIRList() {
    IRList *irList = (IRList *)malloc(sizeof(IRList));
    irList->size = 0;
    irList->capacity = 10;
    irList->instructions = (IRInstruction **)malloc(irList->capacity * sizeof(IRInstruction *));
    return irList;
}

// Function to add an instruction to IRList
void addInstruction(IRList *irList, char *op, char *arg1, char *arg2, char *result) {
    if (irList->size >= irList->capacity) {
        irList->capacity *= 2;
        irList->instructions = (IRInstruction **)realloc(irList->instructions, irList->capacity * sizeof(IRInstruction *));
    }
    IRInstruction *newInst = (IRInstruction *)malloc(sizeof(IRInstruction));
    newInst->op = strdup(op);
    newInst->arg1 = arg1 ? strdup(arg1) : NULL;
    newInst->arg2 = arg2 ? strdup(arg2) : NULL;
    newInst->result = result ? strdup(result) : NULL;
    irList->instructions[irList->size++] = newInst;
}

// Function to print the intermediate code
void printIRList(IRList *irList) {
    for (int i = 0; i < irList->size; i++) {
        IRInstruction *inst = irList->instructions[i];
        printf("%s %s %s %s\n",
               inst->op ? inst->op : "",
               inst->arg1 ? inst->arg1 : "",
               inst->arg2 ? inst->arg2 : "",
               inst->result ? inst->result : "");
    }
}
