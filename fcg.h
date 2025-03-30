#ifndef FCG_H
#define FCG_H

#include <stdio.h>

// Define the structure for holding IRInstructions
typedef struct {
    char *type;
    char *arg1;
    char *arg2;
    char *result;
    char *label;
} IRInstruction;

// Define the structure for holding IRList
typedef struct {
    IRInstruction *instructions;
    int size;
    int capacity;
} IRList;

// Code Generator structure
typedef struct {
    FILE *output_file;
    int temp_var_counter;
} CodeGenerator;

// Function prototypes
IRList* createIRList();
void add_ir_instruction(IRList *irList, const char *type, const char *arg1, const char *arg2, const char *result, const char *label);
void printIRList(IRList *irList);
void generate_assignment(CodeGenerator *gen, IRInstruction *instr);
void generate_addition(CodeGenerator *gen, IRInstruction *instr);
void generate_function_call(CodeGenerator *gen, IRInstruction *instr);
void generate_final_code(CodeGenerator *gen, IRInstruction *ir_code, int num_instructions);

#endif
