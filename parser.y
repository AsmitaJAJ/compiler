%{
#include <stdio.h>
#include "symboltable.h"
#include <string.h>
#include <ctype.h>
#include <stdlib.h> // For malloc and free

#define YYDEBUG 1
int yydebug = 1;
int semantic_error = 0;
extern int linecount;

// Function declarations
int yylex();
void print_symbol_table();
void yyerror(const char *s);

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

// Function prototypes for Intermediate Code Generation
IRList* createIRList();
void add_ir_instruction(IRList *irList, const char *type, const char *arg1, const char *arg2, const char *result, const char *label);
void printIRList(IRList *irList);

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
    yyparse();

    printf("==== Number of Semantic Errors: %d ====\n", semantic_error);

    printIRList(irList);

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