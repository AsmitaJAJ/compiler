#include <stdio.h>
#include <stdlib.h>
#include <string.h>

// Define structure for an intermediate code instruction
typedef struct {
    char *type;    // Type of Instruction e.g declare
    char *arg1;    // Operand 1 (e.g., variable, condition)
    char *arg2;    // Operand 2 (e.g., value to compare with)
    char *result;  // Result (e.g., label to jump to)
    char *op;      // Operator (e.g., 'goto', 'if', '==', etc.)
} IRInstruction;

// Define a list to hold intermediate code instructions
typedef struct {
    IRInstruction **instructions;
    int size;
    int capacity;
} IRList;

// Function to initialize the IRList
IRList* createIRList() {
    IRList *irList = (IRList *)malloc(sizeof(IRList));
    irList->size = 0;
    irList->capacity = 10;
    irList->instructions = (IRInstruction **)malloc(irList->capacity * sizeof(IRInstruction *));
    return irList;
}
// Function to add an instruction to the IRList
void addInstruction(IRList *irList, char *op, char *arg1, char *arg2, char *result) {
    if (irList->size >= irList->capacity) {
        irList->capacity *= 2;
        irList->instructions = (IRInstruction **)realloc(irList->instructions, irList->capacity * sizeof(IRInstruction *));
    }
    IRInstruction *newInst = (IRInstruction *)malloc(sizeof(IRInstruction));
    newInst->op = strdup(op);
    newInst->arg1 = strdup(arg1);
    newInst->arg2 = strdup(arg2);
    newInst->result = strdup(result);
    irList->instructions[irList->size++] = newInst;
}
// Function to generate intermediate code for an if-else structure
void generateIfElse(IRList *irList, char *condition, char *trueLabel, char *falseLabel) {
    // Generate the conditional jump instruction
    addInstruction(irList, "if", condition, "", trueLabel);  // Jump to trueLabel if condition is true

    // Generate the false case (else)
    addInstruction(irList, "goto", "", "", falseLabel); // Always jump to falseLabel

    // Generate the label for the true block
    addInstruction(irList, "label", "", "", trueLabel);

    // Generate the code for the true block (this would be generated separately)
    addInstruction(irList, "true_block", "", "", "");  // Placeholder for actual true block code

    // Generate the label for the false block
    addInstruction(irList, "label", "", "", falseLabel);

    // Generate the code for the false block (this would be generated separately)
    addInstruction(irList, "false_block", "", "", "");  // Placeholder for actual false block code
}
// Function to print the intermediate code instructions
void printIRList(IRList *irList) {
    for (int i = 0; i < irList->size; i++) {
        IRInstruction *inst = irList->instructions[i];
        if (inst->arg2[0] == '\0') { // Single operand instruction (e.g., assignment, label)
            printf("%s %s\n", inst->op, inst->arg1);
        } else { // Conditional jump or operation instruction
            printf("%s %s %s %s\n", inst->op, inst->arg1, inst->arg2, inst->result);
        }
    }
}

// Function to generate intermediate code for a function declaration
void generate_function_declaration_ir(IRCode *ir_code, const char *return_type, const char *function_name, const char *params) {
    // 1. Declare the function: Just the signature (return type and params)
    add_ir_instruction(ir_code, "declare", return_type, function_name, params, "");
}

// Function to generate intermediate code for a declaration statement
void generate_declaration_ir(IRCode *ir_code, const char *type, const char *var_name, const char *init_value) {
    // 1. Generate the declaration (just allocating memory, no value)
    add_ir_instruction(ir_code, "declare", type, var_name, "", "");

    // 2. If there is an initialization, generate the assignment
    if (init_value) {
        add_ir_instruction(ir_code, "assign", var_name, init_value, "", "");
    }
}
// Function to generate intermediate code for an if-else structure
void generateIfElse(IRList *irList, char *condition, char *trueLabel, char *falseLabel) {
    // Generate the conditional jump instruction
    addInstruction(irList, "if", condition, "", trueLabel);  // Jump to trueLabel if condition is true

    // Generate the false case (else)
    addInstruction(irList, "goto", "", "", falseLabel); // Always jump to falseLabel

    // Generate the label for the true block
    addInstruction(irList, "label", "", "", trueLabel);

    // Generate the code for the true block (this would be generated separately)
    addInstruction(irList, "true_block", "", "", "");  // Placeholder for actual true block code

    // Generate the label for the false block
    addInstruction(irList, "label", "", "", falseLabel);

    // Generate the code for the false block (this would be generated separately)
    addInstruction(irList, "false_block", "", "", "");  // Placeholder for actual false block code
}

// Function to generate intermediate code for a while-do loop
void generate_while_do_ir(IRCode *ir_code, const char *condition, const char *loop_body) {
    // Generate labels
    static int label_counter = 0;
    char start_label[10], end_label[10];
    snprintf(start_label, sizeof(start_label), "L%d", label_counter++);
    snprintf(end_label, sizeof(end_label), "L%d", label_counter++);

    // 1. Generate the start label (loop condition check)
    add_ir_instruction(ir_code, "label", start_label, NULL, NULL, NULL);

    // 2. Generate the condition check: if false, jump to the end of the loop
    add_ir_instruction(ir_code, "if", condition, "", end_label, NULL); // if condition is false, jump to end_label

    // 3. Generate the body of the loop (could be a set of instructions)
    add_ir_instruction(ir_code, "assign", "temp_result", loop_body, "", NULL);  // For simplicity, treating the loop body as an assignment

    // 4. Generate a jump back to the start of the loop (condition check)
    add_ir_instruction(ir_code, "jump", "", "", start_label, NULL); // Jump to start_label for next iteration

    // 5. Generate the end label (exit the loop)
    add_ir_instruction(ir_code, "label", end_label, NULL, NULL, NULL);
}
