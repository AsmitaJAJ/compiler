%{
#include "parser.tab.h"
#include <stdio.h>
#include <string.h>
#include <ctype.h>

void initialize_table()
{
    FILE *file = fopen("symbol_table.csv", "w");
    if (!file)
    {
        perror("Error initializing symbol_table.csv");
        exit(EXIT_FAILURE);
    }
    fprintf(file, "Token,Type,Description\n");
    fclose(file);
}

void insert_to_table(char token[],char token_type[],char token_desc[])
{
    FILE *file;
    file=fopen("symbol_table.csv","a+");
    fprintf(file,"%s,%s,%s\n",token,token_type,token_desc);
    fclose(file);
}

void print_table() 
{
    FILE *file = fopen("symbol_table.csv", "r");
    if (!file) {
        perror("Error reading symbol_table.csv");
        return;
    }

    char buffer[1024];
    while (fgets(buffer, sizeof(buffer), file)) {
        printf("%s", buffer);
    }
    fclose(file);
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

"," { printf("%s Delimiter\n", yytext);}

'.*' { 
    if (strchr(yytext, '\n')) {
        printf("Error: String cannot span multiple lines\n");
    } else {
        printf("%s String\n", yytext);
        insert_to_table(yytext,"String","NULL");
    }
}


"=="|"<="|"<>"|">="|">"|"<" { 
    printf("%s Relatonal Operator\n", yytext);
    char type[200]="Default";
    switch(yytext[0])
    {
        case '=': strcpy(type,"Less than");break;
        case '<':
        if(yytext[1]=='\0')
        {
            strcpy(type,"Less than");
        }
        if(yytext[1]=='>')
        {
            strcpy(type,"Not Equal to");
        }
        break;
        if(yytext[1]=='=')
        {
            strcpy(type,"Less than Equal to");
        }break;
        case '>':
        if(yytext[1]=='\0')
        {
            strcpy(type,"Greater than");
        }
        else if(yytext[1]=='=')
        {
            strcpy(type,"Greater than Equal to");
        }break;
    }
    insert_to_table(yytext,"Relational Operator",type);
}

"="     { printf("%s Assignment Operator\n", yytext); insert_to_table(yytext,"Assignment Operator","NULL"); }

"+"|"-"|"*"|"/"|"%" { 
    printf("%s Arithmetic Operator\n", yytext);
    char type[200]="Default";
    switch(yytext[0])
    {
        case '+':strcpy(type,"add");break;
        case '-':strcpy(type,"sub");break;
        case '*':strcpy(type,"mul");break;
        case '/':strcpy(type,"div");break;
        case '%':strcpy(type,"mod");break;
    }
    insert_to_table(yytext,"Arithmetic Operator",type);
}

"!"[^\n]* { printf("%s Comment\n", yytext);}
\n { ; }
\"[^\"]*\n { printf("Error: String cannot span multiple lines\n"); }
. { printf("Unknown character: %s\n", yytext); }
%%

int main(void)
{
    initialize_table();
    yylex();
}