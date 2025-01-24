%{
#include "parser.tab.h"
#include <stdio.h>

%}

%%
[0-9]+    { printf("%s\n", yytext);}
[a-z]+   {printf("%s\n", yytext);}
!.*\n   { printf("%s", yytext); }


%%

