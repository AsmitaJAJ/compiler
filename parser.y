
%{
#include <stdio.h>
#include "symboltable.h"
#include <string.h>
#include <ctype.h>
#include <stdlib.h> // Added for malloc and free

#define YYDEBUG 1
int yydebug = 1;
int semantic_error = 0;
extern int linecount;

// To make sure the identifier is a character pointer, not an int
int yylex();
void print_symbol_table();
void yyerror(const char *s);

// Defining IRInstruction and IRList structures
typedef struct {
    char *type;   // Type of instruction (e.g., 'declare', 'if', 'assign', etc.)
    char *arg1;   // Operand 1 (e.g., variable, condition)
    char *arg2;   // Operand 2 (e.g., value to compare with)
    char *result; // Result (e.g., label to jump to)
    char *op;     // Operator (e.g., 'goto', 'if', '==', etc.)
    char *label;  // Optional field for labels (e.g., for jump instructions)
} IRInstruction;

typedef struct {
    IRInstruction *instructions; // Array of instructions
    int size;                    // Current number of instructions
    int capacity;                // Capacity of the instructions array
} IRList;

// Function prototypes for Intermediate Code Generation
IRList* createIRList();
void add_ir_instruction(IRList *irList, const char *type, const char *arg1, const char *arg2, const char *result, const char *label);
void printIRList(IRList *irList);

// Defining the intermediate code generation variables
int ic_idx = 0;
int temp_var = 0;
int label = 0;
int is_for = 0;
int is_ifelse = 0;

char icg[50][100];

// Make the irList global so that we can access it in the actions
IRList *irList;
%}

%union {
    char* str;  // For IDENTIFIER
    int num;    // For NUMBER
}

%token PROGRAM FUNCTION PROCEDURE PRINTFF INCLUDE
%token IF ELSE THEN DO WHILE OR NOT AND END OF FOR
%token INTEGER VAR ARRAY NUMBER
%token READ WRITE BEGIN_SYM END_SYM
%token <str> IDENTIFIER STRING
%token ASSIGNOP RELOP ADDOP MULOP
%token LPAREN RPAREN LBRACKET RBRACKET LCURLBRACKET RCURLBRACKET COMMA SEMICOLON

%start program

%%
program:
    function_declaration
;

function_declaration:
    FUNCTION IDENTIFIER LPAREN parameter_list RPAREN LCURLBRACKET statement_list RCURLBRACKET
;

parameter_list:
    /*empty*/
    |INTEGER IDENTIFIER { insert_symbol($2, "int", linecount); print_symbol_table();}
    |VAR IDENTIFIER { insert_symbol($2, "var", linecount); print_symbol_table();}
    |parameter_list SEMICOLON parameter_list
;

statement_list:
    /*empty*/
    |declaration_statement statement_list
    |assignment_statement statement_list
    |IF LPAREN expression RPAREN LCURLBRACKET statement_list RCURLBRACKET ELSE LCURLBRACKET statement_list RCURLBRACKET
    |WHILE LPAREN expression RPAREN DO LCURLBRACKET statement_list RCURLBRACKET
    |FOR LPAREN expression RPAREN LCURLBRACKET statement_list RCURLBRACKET
    |READ IDENTIFIER SEMICOLON statement_list
    {
        Symbol* sym = lookup_symbol($2);
        if(sym)
        {
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
        }
        else
        {
            printf("\nVariable not declared");
        }
    }
    |WRITE expression SEMICOLON statement_list
;

declaration_statement:
    INTEGER IDENTIFIER SEMICOLON {
        insert_symbol($2, "int", linecount); print_symbol_table();
        add_ir_instruction(irList, "declare", "int", $2, "", "");}
    |VAR IDENTIFIER SEMICOLON {
        insert_symbol($2, "var", linecount); print_symbol_table();
        add_ir_instruction(irList, "declare", "var", $2, "", "");}
    |INTEGER ARRAY  LBRACKET INTEGER RBRACKET IDENTIFIER {
        insert_symbol($6, "int_arr", linecount); print_symbol_table();}
    |VAR ARRAY LBRACKET INTEGER RBRACKET IDENTIFIER {
        insert_symbol($6, "var_arr", linecount); print_symbol_table();}
    |INTEGER IDENTIFIER ASSIGNOP NUMBER SEMICOLON {
        insert_symbol($2, "int", linecount); print_symbol_table();}
;

assignment_statement:
    IDENTIFIER ASSIGNOP INTEGER SEMICOLON
    {
        if (!lookup_symbol($1)) {
            printf("====Error: Line Number: %d, Variable %s not declared before assignment====\n", linecount, $1);
            semantic_error++;
        } else {
            printf("Assignment successful for %s\n", $1);
        }
    }
    | IDENTIFIER ASSIGNOP STRING SEMICOLON
    {
        if (!lookup_symbol($1)) {
            printf("====Error: Line Number: %d, Variable %s not declared before assignment====\n", linecount, $1);
            semantic_error++;
        } else {
            printf("Assignment successful for %s\n", $1);
        }
    }
    | IDENTIFIER ASSIGNOP NUMBER SEMICOLON
    {
        if (!lookup_symbol($1)) {
            printf("====Error: Line Number: %d, Variable %s not declared before assignment====\n", linecount, $1);
            semantic_error++;
        } else {
            printf("Assignment successful for %s\n", $1);
        }
    }
;

expression:
    NUMBER
    |STRING
    |INTEGER
    |IDENTIFIER RELOP NUMBER
    |IDENTIFIER RELOP STRING
    |IDENTIFIER RELOP INTEGER
;

%%

int main(void) {
    #ifdef YYDEBUG
        yydebug = 1;
    #endif

    // Create an empty IRList
    irList = createIRList();

    yyparse();

    printf("==== Number of Semantic Errors: %d\n",semantic_error);

    // Print the generated intermediate code
    printIRList(irList);

    // Free allocated memory
    free(irList->instructions);
    free(irList);

    return 0;
}

void yyerror(const char *s)
{
    printf("Error: %s\n",s);
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
        if (inst->arg2 == NULL || inst->arg2[0] == '\0') { // Single operand instruction
            printf("%s %s\n", inst->op, inst->arg1);
        } else { // Conditional or binary operation instruction
            printf("%s %s %s %s\n", inst->op, inst->arg1, inst->arg2, inst->result);
        }
    }
}
