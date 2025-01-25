%{
#include "parser.tab.h"
#include <stdio.h>
#include <string.h>
#include <ctype.h>

void insert_to_table(char token[],char token_type[],char token_desc[])
{
    FILE *file;
    file=fopen("symbol_table.csv","a+");
    fprintf(file,"%s,%s,%s\n",token,token_type,token_desc);
    fclose(file);
}

void print_table()
{
    FILE *file;
    file=fopen("symbol_table.csv","r");
    char buffer[1024];
    int row = 0;
    int column = 0;
    while (fgets(buffer,1024, file))
    {
        column = 0;
        row++;
        char* value = strtok(buffer, ", ");
        printf("%s", value);
        value = strtok(NULL, ", ");
        column++;
    }
}
%}

%option case-insensitive
%%

[a-zA-Z][a-zA-Z0-9]* {
    char *key[] = {"and", "array", "begin", "integer", "do", "else", "end", "function", 
                   "if", "of", "or", "not", "procedure", "program", "read", "then", 
                   "var", "while", "write", NULL};
    char significant_part[32 + 1];
    int k = 0;

    strncpy(significant_part, yytext, 32); 
    significant_part[32] = '\0';

    for (int i = 0; key[i]; i++) {
        if (strcmp(significant_part, key[i]) == 0) {
            k = 1; // Found a keyword
            break;
        }
    }
    if (k) 
    {
        printf("Keyword: %s\n", yytext);
        insert_to_table(yytext,"Keyword","NULL");
    } 
    else
    {
        printf("Identifier: %s (Significant part: %s)\n", yytext, significant_part);
        insert_to_table(yytext,"Identifier",significant_part);
    }

}

[0-9]+ { printf("%s Numeric constant\n", yytext); insert_to_table(yytext,"Numeric constant","NULL"); }

[ \t]+ ; 

"," { printf("%s Delimiter\n", yytext); insert_to_table(yytext,"Delimiter","NULL");}

'.*' { 
    if (strchr(yytext, '\n')) {
        printf("Error: String cannot span multiple lines\n");
    } else {
        printf("%s String\n", yytext);
        insert_to_table(yytext,"String","NULL");
    }
}
"=" { printf("%s Equal\n", yytext); insert_to_table(yytext,"Equal","NULL"); }
"<" { printf("%s Less than\n", yytext); insert_to_table(yytext,"Less than","NULL"); }
">" { printf("%s Greater than\n", yytext); insert_to_table(yytext,"Greater than","NULL");}
"<=" { printf("%s Less than or equal\n", yytext); insert_to_table(yytext,"Less than or equal","NULL");}
">=" { printf("%s Greater than or equal\n", yytext); insert_to_table(yytext,"Greater than or equal","NULL");}
"<>" { printf("%s Not equal\n", yytext); insert_to_table(yytext,"Not equal","NULL");}
"!"[^\n]* { printf("%s Comment\n", yytext);}
\n { ; }
\"[^\"]*\n { printf("Error: String cannot span multiple lines\n"); }
. { printf("Unknown character: %s\n", yytext); }
%%

int main(void)
{
    yylex();
}
