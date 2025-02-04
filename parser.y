%{
#include <stdio.h>

int yylex();

void yyerror(const char *s);
%}

%token PROGRAM FUNCTION PROCEDURE 
%token IF ELSE THEN DO WHILE OR NOT AND END OF
%token INTEGER VAR ARRAY
%token READ WRITE BEGIN_SYM END_SYM
%token IDENTIFIER NUMBER STRING
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
    |IDENTIFIER
    |IDENTIFIER SEMICOLON parameter_list
;
statement_list:
    /*empty*/
    |VAR IDENTIFIER  expression SEMICOLON statement_list 
    |INTEGER IDENTIFIER ASSIGNOP NUMBER SEMICOLON statement_list 
    |ARRAY LBRACKET NUMBER RBRACKET IDENTIFIER SEMICOLON statement_list 
    |IF LPAREN expression RPAREN THEN LPAREN statement_list RPAREN ELSE LPAREN statement_list RPAREN
    |WHILE LPAREN expression RPAREN DO LPAREN statement_list RPAREN
    |READ IDENTIFIER SEMICOLON statement_list
    |WRITE expression SEMICOLON statement_list
       

;
expression:
    NUMBER
    |STRING
    |INTEGER
    |RELOP NUMBER
    |RELOP STRING
    |RELOP INTEGER
    |ASSIGNOP NUMBER
    |ASSIGNOP STRING
    |ASSIGNOP INTEGER
    
    ;

%%

int main(void) {
    yyparse();  
}

void yyerror(const char *s)
{
    printf("Error: %s\n",s);
}



