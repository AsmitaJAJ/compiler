%{
#define _GNU_SOURCE
#define __STDC_WANT_LIB_EXT2__ 1

#include <stdio.h>
#include "symboltable.h"
#include <string.h>
#include <ctype.h>
#include <stdlib.h> // For malloc and free
#include <stdarg.h>

int my_asprintf(char **strp, const char *fmt, ...);



#define YYDEBUG 1
int yydebug = 1;
int semantic_error = 0;
extern int linecount;

// Defining Intermediate Representation (IR) structures
typedef struct {
    char *type;   // Instruction type (e.g., 'declare', 'assign', 'if')
    char *arg1;   // Operand 1
    char *arg2;   // Operand 2 (if needed)
    char *result; // Result variable
    char *label;  // Optional label for jumps
} IRInstruction;

typedef struct {
    IRInstruction *instructions;
    int size;
    int capacity;
} IRList;


// Function declarations
int yylex();
void print_symbol_table();
void yyerror(const char *s);


// Function prototypes for Intermediate Code Generation and Target Code Generation
IRList* createIRList();
void add_ir_instruction(IRList *irList, const char *type, const char *arg1, const char *arg2, const char *result, const char *label);
void printIRList(IRList *irList);
void generateTargetCode(IRList *irList, int instruction_count);
// Defining IR-related variables
IRList *irList;

%}

// Defining the union for different token types
%union {
    char* str;  // For IDENTIFIER, STRING, RELOP, expressions
    int num;    // For NUMBER
}

%token PROGRAM FUNCTION PROCEDURE PRINTFF INCLUDE
%token IF ELSE THEN DO WHILE OR NOT AND END OF FOR
%token INTEGER VAR ARRAY
%token READ WRITE BEGIN_SYM END_SYM
%token <str> IDENTIFIER STRING RELOP   // Added RELOP as a string
%token <num> NUMBER
%token ASSIGNOP ADDOP MULOP
%token LPAREN RPAREN LBRACKET RBRACKET LCURLBRACKET RCURLBRACKET COMMA SEMICOLON

%type <str> expression  // Expression should return a string for IR

%start program

%%

program:
    function_declaration
;

function_declaration:
    FUNCTION IDENTIFIER LPAREN parameter_list RPAREN LCURLBRACKET statement_list RCURLBRACKET
;

parameter_list:
    /* empty */
    | INTEGER IDENTIFIER { insert_symbol($2, "int", linecount); print_symbol_table(); }
    | VAR IDENTIFIER { insert_symbol($2, "var", linecount); print_symbol_table(); }
    | parameter_list SEMICOLON parameter_list
;

statement_list:
    /* empty */
    | declaration_statement statement_list
    | assignment_statement statement_list
    | IF LPAREN expression RPAREN LCURLBRACKET statement_list RCURLBRACKET ELSE LCURLBRACKET statement_list RCURLBRACKET
        { add_ir_instruction(irList, "IF", $3, "", "LABEL_TRUE", ""); }
    | WHILE LPAREN expression RPAREN DO LCURLBRACKET statement_list RCURLBRACKET
        { add_ir_instruction(irList, "WHILE", $3, "", "LOOP_START", ""); }
    | FOR LPAREN expression RPAREN LCURLBRACKET statement_list RCURLBRACKET
        { add_ir_instruction(irList, "FOR", $3, "", "FOR_LOOP", ""); }
    | READ IDENTIFIER SEMICOLON statement_list
        {
            Symbol* sym = lookup_symbol($2);
            if (sym) {
                if (strcmp(sym->type, "int") == 0) {
                    int value;
                    printf("Enter an integer: ");
                    scanf("%d", &value);
                    printf("Stored %d in %s\n", value, sym->name);
                } else if (strcmp(sym->type, "var") == 0) {
                    char value[100];
                    printf("Enter a string: ");
                    scanf("%s", value);
                    printf("Stored %s in %s\n", value, sym->name);
                }
            } else {
                printf("\nVariable not declared");
            }
        }
    | WRITE expression SEMICOLON statement_list
        { add_ir_instruction(irList, "WRITE", $2, "", "", ""); }
;

declaration_statement:
    INTEGER IDENTIFIER SEMICOLON
        { insert_symbol($2, "int", linecount); print_symbol_table();
          add_ir_instruction(irList, "DECLARE", "int", $2, "", ""); }
    | VAR IDENTIFIER SEMICOLON
        { insert_symbol($2, "var", linecount); print_symbol_table();
          add_ir_instruction(irList, "DECLARE", "var", $2, "", ""); }
;

assignment_statement:
    IDENTIFIER ASSIGNOP expression SEMICOLON
        { 
            if (!lookup_symbol($1)) {
                printf("==== Error: Line %d, Variable %s not declared before assignment ====\n", linecount, $1);
                semantic_error++;
            } else {
                add_ir_instruction(irList, "ASSIGN", $3, "", $1, "");
            }
        }
;

expression:
    NUMBER        { my_asprintf(&$$, "%d", $1); }  // Convert int to string
    | STRING      { $$ = strdup($1); }
    | IDENTIFIER  { $$ = strdup($1); }
    | IDENTIFIER RELOP NUMBER { my_asprintf(&$$, "%s %s %d", $1, $2, $3); }
    | IDENTIFIER RELOP STRING { my_asprintf(&$$, "%s %s %s", $1, $2, $3); }
    | IDENTIFIER RELOP IDENTIFIER { my_asprintf(&$$, "%s %s %s", $1, $2, $3); }
;

%%

int main(void) {
    #ifdef YYDEBUG
        yydebug = 1;
    #endif

    irList = createIRList();
    yyparse();

    printf("==== Number of Semantic Errors: %d ====\n", semantic_error);

    printIRList(irList);

    // Call the Target Code Generation Function - If Semantic Errors are zero
    int size = irList->size;
    
    printf("====Generating Target Code====\n");
    generateTargetCode(irList, size);
    printf("===Target Code Generation Done===\n");
    free(irList->instructions);
    free(irList);

    return 0;
}

void yyerror(const char *s) {
    printf("Error: %s\n", s);
}

//==================== Intermediate Code Generation Functions =====================

IRList* createIRList() {
    IRList *irList = (IRList *)malloc(sizeof(IRList));
    irList->size = 0;
    irList->capacity = 10;
    irList->instructions = (IRInstruction *)malloc(irList->capacity * sizeof(IRInstruction));
    return irList;
}

void add_ir_instruction(IRList *irList, const char *type, const char *arg1, const char *arg2, const char *result, const char *label) {
    if (irList->size >= irList->capacity) {
        irList->capacity *= 2;
        irList->instructions = (IRInstruction *)realloc(irList->instructions, irList->capacity * sizeof(IRInstruction));
    }

    IRInstruction *instr = &irList->instructions[irList->size];
    instr->type = strdup(type);
    instr->arg1 = strdup(arg1);
    instr->arg2 = strdup(arg2);
    instr->result = strdup(result);
    instr->label = strdup(label);

    irList->size++;
}

void printIRList(IRList *irList) {
    for (int i = 0; i < irList->size; i++) {
        IRInstruction *inst = &irList->instructions[i];
        printf("%s %s %s %s %s\n", inst->type, inst->arg1, inst->arg2, inst->result, inst->label);
    }
}

//========= Target Code Generation module ========//
void generateTargetCode(IRList *irList, int instruction_count) {
    static int label_count = 0;  // Static label counter to keep track of unique labels

    // Generate target code from intermediate code array
    for (int i = 0; i < instruction_count; i++) {

        IRInstruction* ir = &irList->instructions[i];
        
        // Process each instruction and convert it to target code
        printf("Generating code for: %s\n", ir->type);

        if (strcmp(ir->type, "DECLARE") == 0) {
            // Generate code for variable declaration (allocating space)
            printf("ALLOC 4, %s  // Allocating space for %s (4 bytes)\n", ir->result, ir->result);
        } else if (strcmp(ir->type, "ASSIGN") == 0) {
            // Generate code for variable assignment
            printf("MOV %s, %s  // Initializing %s with value %s\n", ir->result, ir->arg1, ir->result, ir->arg1);
        } else if (strcmp(ir->type, "OPER") == 0) {
            // Code to generate assembly code for a given Operation (e.g., ADD, SUB)
            if (strcmp(ir->arg1, "+") == 0) {
                printf("  ADD %s, %s, %s\n", ir->result, ir->arg1, ir->arg2);
            } else if (strcmp(ir->arg1, "-") == 0) {
                printf("  SUB %s, %s, %s\n", ir->result, ir->arg1, ir->arg2);
            } else if (strcmp(ir->arg1, "*") == 0) {
                printf("  MUL %s, %s, %s\n", ir->result, ir->arg1, ir->arg2);
            } else if (strcmp(ir->arg1, "/") == 0) {
                printf("  DIV %s, %s, %s\n", ir->result, ir->arg1, ir->arg2);
            } else {
                printf("  ; Unsupported operator %s\n", ir->arg1);
            }
        } else if (strcmp(ir->type, "IF") == 0) {
            // Code for IF-THEN-ELSE structure
            int then_label = label_count++;
            int else_label = label_count++;
            int end_label = label_count++;

            // Generate label for the then and else blocks
            printf("  ; Evaluating condition: %s\n", ir->arg1);
            printf("  CMP %s, 0\n", ir->arg1);  // Assume the condition is a variable to compare with 0
            printf("  JE else_%d\n", else_label);

            // If condition is true, execute the then block
            printf("  ; Then block\n");
            printf("  ; %s\n", ir->result);  // Print the then statement

            // Jump to end to skip the else block
            printf("  JMP end_%d\n", end_label);

            // Else block label
            printf("else_%d:\n", else_label);
            printf("  ; Else block\n");
            printf("  ; %s\n", ir->result);  // Print the else statement

            // End label
            printf("end_%d:\n", end_label);
        } else if (strcmp(ir->type, "WHILE") == 0) {
            // Code for while-do loop structure
            int start_label = label_count++;
            int end_label = label_count++;

            // Generate labels for the start and end of the loop
            printf("loop_%d:\n", start_label);

            // Evaluate the condition at the beginning of the loop
            printf("  ; Evaluating condition: %s\n", ir->arg1);
            printf("  CMP %s, 0\n", ir->arg1);  // Assuming the condition is a variable or expression
            printf("  JE end_%d\n", end_label);      // Jump to the end if condition is false

            // Loop body (do block)
            printf("  ; Loop body (do block)\n");
            printf("  ; %s\n", ir->result);  // Print the loop body statement

            // Jump back to the start to re-evaluate the condition
            printf("  JMP loop_%d\n", start_label);

            // End label for the loop (exit point)
            printf("end_%d:\n", end_label);
        }
    }
}



//=== To address issue about my_asprintf on windows platform


int my_asprintf(char **strp, const char *fmt, ...) {
    va_list args;
    va_start(args, fmt);

    va_list args_copy;
    va_copy(args_copy, args);
    int len = vsnprintf(NULL, 0, fmt, args_copy);
    va_end(args_copy);

    if (len < 0) {
        va_end(args);
        return -1;  // Formatting error
    }

    *strp = malloc(len + 1);
    if (!*strp) {
        va_end(args);
        return -1;  // Memory allocation failed
    }

    vsnprintf(*strp, len + 1, fmt, args);
    va_end(args);
    return len;  // Return number of characters written (excluding null terminator)
}

