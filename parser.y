%{
#define _GNU_SOURCE
#define __STDC_WANT_LIB_EXT2__ 1

#include <stdio.h>
#include "symboltable.h"
#include <string.h>
#include <ctype.h>
#include <stdlib.h> // For malloc and free
#include <stdarg.h>


#define YYDEBUG 1
int yydebug = 1;
int semantic_error = 0;
extern int linecount;
extern SemError* semerrorTable[100];

// Defining Intermediate Representation (IR) structures
typedef struct {
    char *linenumber; // Line Number from the input file
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
void print_semantic_errors();
void yyerror(const char *s);


// Function prototypes for Intermediate Code Generation and Target Code Generation
IRList* createIRList();
void add_ir_instruction(IRList *irList, const char *linenumber, const char *type, const char *arg1, const char *arg2, const char *result, const char *label);
void printIRList(IRList *irList, FILE *IC_File, FILE *SEMERRORS_FILE_Parser);
void generateTargetCode(IRList *irList, int instruction_count, FILE *TC_File);
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
        { 
            char *linenumber_str;
            asprintf(&linenumber_str, "%d", linecount);
            add_ir_instruction(irList, linenumber_str, "IF", $3, "", "LABEL_TRUE", "");
            free(linenumber_str);
        }
    | WHILE LPAREN expression RPAREN DO LCURLBRACKET statement_list RCURLBRACKET
        { 
            char *linenumber_str;
            asprintf(&linenumber_str, "%d", linecount);
            add_ir_instruction(irList, linenumber_str, "WHILE", $3, "", "LOOP_START", "");
            free(linenumber_str);
        }
    | FOR LPAREN expression RPAREN LCURLBRACKET statement_list RCURLBRACKET
        { 
            char *linenumber_str;
            asprintf(&linenumber_str, "%d", linecount);
            add_ir_instruction(irList, linenumber_str, "FOR", $3, "", "FOR_LOOP", "");
            free(linenumber_str);
        }
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
        { 
            char *linenumber_str;
            asprintf(&linenumber_str, "%d", linecount);
            add_ir_instruction(irList, linenumber_str, "WRITE", $2, "", "", "");
            free(linenumber_str);
        }
;

declaration_statement:
    INTEGER IDENTIFIER SEMICOLON
        {   insert_symbol($2, "int", linecount); print_symbol_table();
          
            char *linenumber_str;
            asprintf(&linenumber_str, "%d", linecount);
            add_ir_instruction(irList, linenumber_str, "DECLARE", "int", $2, "", "");
            free(linenumber_str);
        }
    | VAR IDENTIFIER SEMICOLON
        {   insert_symbol($2, "var", linecount); print_symbol_table();
            char *linenumber_str;
            asprintf(&linenumber_str, "%d", linecount);
            add_ir_instruction(irList, linenumber_str, "DECLARE", "var", $2, "", "");
            free(linenumber_str);
        }
;

assignment_statement:
    IDENTIFIER ASSIGNOP expression SEMICOLON
        { 
            if (!lookup_symbol($1)) {
                printf("==== Error: Line %d, Variable %s not declared before assignment ====\n", linecount, $1);
                semantic_error++;
                write_semantic_errors("Variable not declared before assignment ", linecount, $1);
            } else {
                char *linenumber_str;
                asprintf(&linenumber_str, "%d", linecount);
                add_ir_instruction(irList, linenumber_str, "ASSIGN", $3, "", $1, "");
                free(linenumber_str);
            }
        }
;

expression:
    NUMBER        { asprintf(&$$, "%d", $1); }  // Convert int to string
    | STRING      { $$ = strdup($1); }
    | IDENTIFIER  { $$ = strdup($1); }
    | IDENTIFIER RELOP NUMBER { asprintf(&$$, "%s %s %d", $1, $2, $3); }
    | IDENTIFIER RELOP STRING { asprintf(&$$, "%s %s %s", $1, $2, $3); }
    | IDENTIFIER RELOP IDENTIFIER { asprintf(&$$, "%s %s %s", $1, $2, $3); }
;

%%

int main(void) {
    #ifdef YYDEBUG
        yydebug = 1;
    #endif

    irList = createIRList();

    // Create Files for Intermediate Code and Target Code
    FILE *SEMERRORS_FILE_Parser;
    FILE *IC_File;
    FILE *TC_File;
    
    // Delete the IntermediateCode file if it exists
    if (remove("IntermediateCode") == 0) {
        printf("IntermediateCode File deleted successfully.\n");
    } else {
        printf("IntermediateCode File does not exist or could not be deleted.\n");
    }
    // Delete the TargetCode file if it exists
    if (remove("TargetCode") == 0) {
        printf("TargetCode File deleted successfully.\n");
    } else {
        printf("TargetCode File does not exist or could not be deleted.\n");
    }

    IC_File = fopen("IntermediateCode", "a");
    if (IC_File == NULL) {
        perror("Error opening file - IntermediateCode");
        return 1;
    }

    TC_File = fopen("TargetCode", "a");
    if (TC_File == NULL) {
        perror("Error opening file - TargetCode");
        return 1;
    }
    // Done Creating Files for Intermediate Code and Target Code

    yyparse();

    printf("==== Number of Semantic Errors: %d ====\n", semantic_error);
    print_semantic_errors();

    printIRList(irList, IC_File, SEMERRORS_FILE_Parser);

    // Call the Target Code Generation Function - If Semantic Errors are zero
    if (semantic_error == 0) {
        int size = irList->size;
        generateTargetCode(irList, size, TC_File);
    }
    else { 
        printf("====Target Code not generated - There are %d semantic errors====\n", semantic_error );
    }
    
    free(irList->instructions);
    free(irList);

    // Close the TargetCode file
    fclose(TC_File);
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

void add_ir_instruction(IRList *irList, const char *linenumber, const char *type, const char *arg1, const char *arg2, const char *result, const char *label) {
    if (irList->size >= irList->capacity) {
        irList->capacity *= 2;
        irList->instructions = (IRInstruction *)realloc(irList->instructions, irList->capacity * sizeof(IRInstruction));
    }
    // Add instructions to array
    IRInstruction *instr = &irList->instructions[irList->size];
    instr->linenumber = strdup(linenumber);
    instr->type = strdup(type);
    instr->arg1 = strdup(arg1);
    instr->arg2 = strdup(arg2);
    instr->result = strdup(result);
    instr->label = strdup(label);

    irList->size++;
}

void printIRList(IRList *irList, FILE *IC_File, FILE *SEMERRORS_FILE_Parser) {
    char ch;
    SEMERRORS_FILE_Parser = fopen("SemErrors", "r");
    if (SEMERRORS_FILE_Parser == NULL) {
        perror("Parcer - Error opening file - SemErrors");
        exit(1);
    }

    for (int i = 0; i < irList->size; i++) {
        IRInstruction *inst = &irList->instructions[i];
        printf("LN %s, %s %s %s %s %s\n", inst->linenumber, inst->type, inst->arg1, inst->arg2, inst->result, inst->label);

        // Add instructions to a file with line number and semantic errors if any
        fprintf(IC_File, "LN %s: %s %s %s %s %s\n", inst->linenumber, inst->type, inst->arg1, inst->arg2, inst->result, inst->label);
    }
    // Add the semantic error details at the end
    while ((ch = fgetc(SEMERRORS_FILE_Parser)) != EOF) {
        fputc(ch, IC_File);  // Write each character to the destination file
    }
    fclose(SEMERRORS_FILE_Parser);
    fclose(IC_File);
}

//========= Target Code Generation module ========//
void generateTargetCode(IRList *irList, int instruction_count, FILE *TC_File) {
    static int label_count = 0;  // Static label counter to keep track of unique labels

    // Generate target code from intermediate code array
    for (int i = 0; i < instruction_count; i++) {

        IRInstruction* ir = &irList->instructions[i];
        
        // Process each instruction and convert it to target code
        printf("Generating code for: %s\n", ir->type);

        if (strcmp(ir->type, "DECLARE") == 0) {
            // Generate code for variable declaration (allocating space)
            printf("ALLOC 4, %s  // Allocating space for %s (4 bytes)\n", ir->result, ir->result);
            fprintf(TC_File, "ALLOC 4, %s  // Allocating space for %s (4 bytes)\n", ir->result, ir->result);
        } else if (strcmp(ir->type, "ASSIGN") == 0) {
            // Generate code for variable assignment
            printf("MOV %s, %s  // Initializing %s with value %s\n", ir->result, ir->arg1, ir->result, ir->arg1);
            fprintf(TC_File, "MOV %s, %s  // Initializing %s with value %s\n", ir->result, ir->arg1, ir->result, ir->arg1);
        } else if (strcmp(ir->type, "OPER") == 0) {
            // Code to generate assembly code for a given Operation (e.g., ADD, SUB)
            if (strcmp(ir->arg1, "+") == 0) {
                printf("ADD %s, %s, %s\n", ir->result, ir->arg1, ir->arg2);
                fprintf(TC_File, "ADD %s, %s, %s\n", ir->result, ir->arg1, ir->arg2);
            } else if (strcmp(ir->arg1, "-") == 0) {
                printf("SUB %s, %s, %s\n", ir->result, ir->arg1, ir->arg2);
                fprintf(TC_File, "SUB %s, %s, %s\n", ir->result, ir->arg1, ir->arg2);
            } else if (strcmp(ir->arg1, "*") == 0) {
                printf("MUL %s, %s, %s\n", ir->result, ir->arg1, ir->arg2);
                fprintf(TC_File, "MUL %s, %s, %s\n", ir->result, ir->arg1, ir->arg2);
            } else if (strcmp(ir->arg1, "/") == 0) {
                printf("DIV %s, %s, %s\n", ir->result, ir->arg1, ir->arg2);
                fprintf(TC_File, "DIV %s, %s, %s\n", ir->result, ir->arg1, ir->arg2);
            } else {
                printf("  ; Unsupported operator %s\n", ir->arg1);
                fprintf(TC_File, "  ; Unsupported operator %s\n", ir->arg1);
            }
        } else if (strcmp(ir->type, "IF") == 0) {
            // Code for IF-THEN-ELSE structure
            int then_label = label_count++;
            int else_label = label_count++;
            int end_label = label_count++;

            // Generate label for the then and else blocks
            printf("  ; Evaluating condition: %s\n", ir->arg1);
            fprintf(TC_File, "  ; Evaluating condition: %s\n", ir->arg1);
            printf("  CMP %s, 0\n", ir->arg1);  // Assume the condition is a variable to compare with 0
            fprintf(TC_File, "  CMP %s, 0\n", ir->arg1);
            printf("  JE else_%d\n", else_label);
            fprintf(TC_File, "  JE else_%d\n", else_label);

            // If condition is true, execute the then block
            printf("  ; Then block\n");
            fprintf(TC_File, "  ; Then block\n");
            printf("  ; %s\n", ir->result);  // Print the then statement
            fprintf(TC_File, "  ; %s\n", ir->result);

            // Jump to end to skip the else block
            printf("  JMP end_%d\n", end_label);
            fprintf(TC_File, "  JMP end_%d\n", end_label);

            // Else block label
            printf("else_%d:\n", else_label);
            fprintf(TC_File, "else_%d:\n", else_label);
            printf("  ; Else block\n");
            fprintf(TC_File, "  ; Else block\n");
            printf("  ; %s\n", ir->result);  // Print the else statement
            fprintf(TC_File, "  ; %s\n", ir->result);

            // End label
            printf("end_%d:\n", end_label);
            fprintf(TC_File, "end_%d:\n", end_label);
        } else if (strcmp(ir->type, "WHILE") == 0) {
            // Code for while-do loop structure
            int start_label = label_count++;
            int end_label = label_count++;

            // Generate labels for the start and end of the loop
            printf("loop_%d:\n", start_label);
            fprintf(TC_File, "loop_%d:\n", start_label);

            // Evaluate the condition at the beginning of the loop
            printf("  ; Evaluating condition: %s\n", ir->arg1);
            fprintf(TC_File, "  ; Evaluating condition: %s\n", ir->arg1);
            printf("  CMP %s, 0\n", ir->arg1);  // Assuming the condition is a variable or expression
            fprintf(TC_File, "  CMP %s, 0\n", ir->arg1);
            printf("  JE end_%d\n", end_label);      // Jump to the end if condition is false
            fprintf(TC_File, "  JE end_%d\n", end_label);

            // Loop body (do block)
            printf("  ; Loop body (do block)\n");
            fprintf(TC_File, "  ; Loop body (do block)\n");
            printf("  ; %s\n", ir->result);  // Print the loop body statement
            fprintf(TC_File, "  ; %s\n", ir->result);

            // Jump back to the start to re-evaluate the condition
            printf("  JMP loop_%d\n", start_label);
            fprintf(TC_File, "  JMP loop_%d\n", start_label);

            // End label for the loop (exit point)
            printf("end_%d:\n", end_label);
            fprintf(TC_File, "end_%d:\n", end_label);
        }
    }
}



//=== To address issue about asprintf on windows platform

int asprintf(char **strp, const char *fmt, ...) {
    va_list args;
    int len;

    // Start processing variadic arguments
    va_start(args, fmt);
    
    // Calculate the length of the resulting string
    len = vsnprintf(NULL, 0, fmt, args) + 1;  // +1 for null-terminator
    
    // End the variadic argument processing
    va_end(args);
    
    // Allocate memory for the string
    *strp = (char *)malloc(len);
    if (*strp == NULL) {
        return -1;  // Memory allocation failed
    }

    // Start again to format the string
    va_start(args, fmt);
    
    // Format the string into the allocated memory
    vsnprintf(*strp, len, fmt, args);
    
    // End the variadic argument processing
    va_end(args);

    return len - 1;  // Return the number of characters written (not including null terminator)
}
