
%{
#include "parser.tab.h"
#include "symboltable.h"
#include <stdio.h>
#include <string.h>
int linecount=0;
%}

%option yylineno

alpha [a-zA-Z]
digit [0-9]
unary "++"|"--"

%%
"function"     { return FUNCTION; }
"program"      { return PROGRAM; }
"int"      { return INTEGER; }
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
"for"          { return FOR; }
"read"         { return READ; }
"write"        { return WRITE; }
"procedure"    { return PROCEDURE; }
"printf"       { return PRINTFF; }
^"#include"[ ]*<.+\.h>      { return INCLUDE; }

[a-zA-Z_][a-zA-Z0-9_]* {
    yylval.str = strdup(yytext);  
// Necessary because yytext is overwritten every time yylex() runs.
// Since Bison’s $2 just holds a pointer to yytext, it becomes invalid after yylex() scans the next token.
// We must allocate memory (using strdup) to store a persistent copy of the identifier.

    return IDENTIFIER; 
}

[0-9]+ {
    yylval.num = atoi(yytext);
    return NUMBER;
}

"'.*'"                 {return STRING; }
!.*\n                   { /* Ignore comments */ }
":="       { return ASSIGNOP; }
"=="|"<"|">"|"<="|">="|"<>" { return RELOP; }
"+"|"-"    { return ADDOP; }
"*"|"/"    { return MULOP; }

"("        { return LPAREN; }
")"        { return RPAREN; }
"["        { return LBRACKET; }
"]"        { return RBRACKET; }
"{"        { return LCURLBRACKET; }
"}"        { return RCURLBRACKET; }
","        { return COMMA; }
";"        { return SEMICOLON; }

[ \t]    { /* Ignore whitespace */ }
[\n]       { linecount++; }
.          { printf("Unknown character: %s\n", yytext); }
%%

