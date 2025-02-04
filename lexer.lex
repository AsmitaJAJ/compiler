
%{
#include "parser.tab.h"
#include <stdio.h>

%}

%%
"function"     { return FUNCTION; }
"program"      { return PROGRAM; }
"integer"      { return INTEGER; }
"var"          { return VAR; }
"array"        { return ARRAY; }
"of"           { return OF; }
"begin"        { return BEGIN_SYM; }
"end"          { return END_SYM; }
"if"           { return IF; }
"then"         { return THEN; }
"else"         { return ELSE; }
"while"        { return WHILE; }
"do"           { return DO; }
"read"         { return READ; }
"write"        { return WRITE; }
"procedure"    { return PROCEDURE; }

[a-zA-Z_][a-zA-Z0-9_]*  { return IDENTIFIER; }
[0-9]+                 { return NUMBER; }
"'.*'"                 { return STRING; }
!.*\n                   { /* Ignore comments */ }
":="       { return ASSIGNOP; }
"=="|"<"|">"|"<="|">="|"<>" { return RELOP; }
"+"|"-"    { return ADDOP; }
"*"|"/"    { return MULOP; }

"("        { return LPAREN; }
")"        { return RPAREN; }
"["        { return LBRACKET; }
"]"        { return RBRACKET; }
","        { return COMMA; }
";"        { return SEMICOLON; }

[ \t\n]    { /* Ignore whitespace */ }
.          { printf("Unknown character: %s\n", yytext); }
%%

