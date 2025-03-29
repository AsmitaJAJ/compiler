%{
#include <stdio.h>
#include "symboltable.h" 
#include <string.h>
#include <ctype.h>

#define YYDEBUG 1
int yydebug = 1;
int semantic_error = 0;
extern int linecount;

 //to make sure the identifier is a character pointer not an int
int yylex();
void print_symbol_table();
void yyerror(const char *s);

// Definations for ICG
int ic_idx=0;
int temp_var=0;
int label=0;
int is_for=0;
int is_ifelse=0;

char icg[50][100];

struct node { 
		struct node *left; 
		struct node *right; 
		char *token; 
	};


%}
%union {
    char* str;  // For IDENTIFIER
    int num;    // For NUMBER
}
// Definations for ICG

%union {
    struct {
        char *type;    // Type of Instruction e.g declare
        char *arg1;    // Operand 1 (e.g., variable, condition)
        char *arg2;    // Operand 2 (e.g., value to compare with)
        char *result;  // Result (e.g., label to jump to)
        char *op;      // Operator (e.g., 'goto', 'if', '==', etc.)
    } IRInstruction;
    
    // Define a list to hold intermediate code instructions
    struct {
        IRInstruction *instructions;
        int size;
        int capacity;
    } IRList;
}



// Systax analysis 

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
    |INTEGER IDENTIFIER { insert_symbol($2, "int", linecount);  print_symbol_table();} 
    |VAR IDENTIFIER { insert_symbol($2, "var", linecount); print_symbol_table();}
    |parameter_list SEMICOLON parameter_list
;
statement_list:
    /*empty*/
    |declaration_statement statement_list
    |assignment_statement statement_list
    |IF LPAREN expression RPAREN LCURLBRACKET statement_list RCURLBRACKET ELSE LCURLBRACKET statement_list RCURLBRACKET
    //{
        // ICG code for IF - ELSE
        // Labels for true and false blocks
        //char trueLabel[] = "L1";  // Label for true block
        //char falseLabel[] = "L2"; // Label for false block

        // Generate intermediate code for if-else statement
        //generateIfElse(irList, "x > y", trueLabel, falseLabel);

    //}
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
        add_ir_instruction(ir_code, "declare", "int", $2, "", "");} //$n in bison represents the nth item in a rule
        
    |VAR IDENTIFIER SEMICOLON {
        insert_symbol($2, "var", linecount); print_symbol_table();
        add_ir_instruction(ir_code, "declare", "var", $2, "", "");}
    |INTEGER ARRAY  LBRACKET INTEGER RBRACKET IDENTIFIER {
        insert_symbol($6, "int_arr", linecount); print_symbol_table();
        //add_ir_instruction(IRCode *ir_code, "declare", "int_arr", $2, "", "");
        }
    |VAR ARRAY LBRACKET INTEGER RBRACKET IDENTIFIER { 
        insert_symbol($6, "var_arr", linecount); print_symbol_table();
        //add_ir_instruction(IRCode *ir_code, "declare", "var_arr", $2, "", "");
        }
    |INTEGER IDENTIFIER ASSIGNOP NUMBER SEMICOLON { 
        insert_symbol($2, "int", linecount); print_symbol_table();
        //add_ir_instruction(IRCode *ir_code, "declare", "int", $2, "", "");
        }


    
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

    // Create an empty ICG Instruction List
    IRList *irList = createIRList();

    yyparse();  

    printf("==== Number of Semantic Errors: %d\n",semantic_error);

    // Print the generated intermediate code
    printIRList(irList);

    // Free allocated memory (skipping for brevity in this simple example)
    return 0;

    // if semantic_error == 0, then call the fcg module else print Error
}

void yyerror(const char *s)
{
    printf("Error: %s\n",s);
}

//============== Various functions for intermediate Code Generation <TBD Chatgpt code needs some changes=================//

// Function to initialize the IRList - chatgpt
IRList* createIRList() {
    IRCode *ir_code = (IRCode *)malloc(sizeof(IRCode));
    ir_code->size = 0;
    ir_code->capacity = 10;
    ir_code->instructions = (IRInstruction *)malloc(ir_code->capacity * sizeof(IRInstruction));
    return ir_code;
}

// Function to add an instruction to IR code
void add_ir_instruction(IRCode *ir_code, const char *type, const char *var1, const char *var2, const char *result, const char *label) {
    if (ir_code->size >= ir_code->capacity) {
        ir_code->capacity *= 2;
        ir_code->instructions = (IRInstruction *)realloc(ir_code->instructions, ir_code->capacity * sizeof(IRInstruction));
    }

    IRInstruction *instr = &ir_code->instructions[ir_code->size];
    strcpy(instr->type, type);
    if (var1) strcpy(instr->var1, var1);
    if (var2) strcpy(instr->var2, var2);
    if (result) strcpy(instr->result, result);
    if (label) strcpy(instr->label, label);

    ir_code->size++;
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
