%{
#include <stdio.h>
#include "symboltable.h" 
#include <string.h>
 //to make sure the identifier is a character pointer not an int
int yylex();
void print_symbol_table();
void yyerror(const char *s);
%}
%union {
    char* str;  // For IDENTIFIER
    int num;    // For NUMBER
}

%token PROGRAM FUNCTION PROCEDURE 
%token IF ELSE THEN DO WHILE OR NOT AND END OF
%token INTEGER VAR ARRAY NUMBER
%token READ WRITE BEGIN_SYM END_SYM
%token <str> IDENTIFIER STRING
%token ASSIGNOP RELOP ADDOP MULOP
%token LPAREN RPAREN LBRACKET RBRACKET COMMA SEMICOLON



%start program 

%%
program:
    function_declaration
;
function_declaration:
    FUNCTION IDENTIFIER LPAREN parameter_list RPAREN LPAREN statement_list RPAREN
;

parameter_list:
    /*empty*/
    |INTEGER IDENTIFIER {  insert_symbol($2, "int");  print_symbol_table();} 
    |VAR IDENTIFIER { insert_symbol($2, "var"); print_symbol_table();}
    |parameter_list SEMICOLON parameter_list
;
statement_list:
    /*empty*/
    |declaration_statement statement_list
    |assignment_statement statement_list
    |IF LPAREN expression RPAREN THEN LPAREN statement_list RPAREN ELSE LPAREN statement_list RPAREN
    |WHILE LPAREN expression RPAREN DO LPAREN statement_list RPAREN
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
    INTEGER IDENTIFIER SEMICOLON {  insert_symbol($2, "int");  print_symbol_table();} //$n in bison represents the nth item in a rule
    |VAR IDENTIFIER SEMICOLON { insert_symbol($2, "var"); print_symbol_table();}
    |INTEGER ARRAY  LBRACKET INTEGER RBRACKET IDENTIFIER{ insert_symbol($6, "int_arr"); }
     |VAR ARRAY LBRACKET INTEGER RBRACKET IDENTIFIER { insert_symbol($6, "var_arr"); }
;

assignment_statement:
    IDENTIFIER ASSIGNOP INTEGER SEMICOLON
    {
        if (!lookup_symbol($1)) { 
            printf("Error: Variable %s not declared before assignment\n", $1); 
        } else { 
            printf("Assignment successful for %s\n", $1);
        }
    }
    | IDENTIFIER ASSIGNOP STRING SEMICOLON
    {
        if (!lookup_symbol($1)) { 
            printf("Error: Variable %s not declared before assignment\n", $1); 
        } else { 
            printf("Assignment successful for %s\n", $1);
        }
    }
    | IDENTIFIER ASSIGNOP NUMBER SEMICOLON
    {
        if (!lookup_symbol($1)) { 
            printf("Error: Variable %s not declared before assignment\n", $1); 
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
    yyparse();  
}

void yyerror(const char *s)
{
    printf("Error: %s\n",s);
}


