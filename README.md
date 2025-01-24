to run use makefile with the commands:

all:
	bison -t -d -v parser.y
	flex lexer.lex
	gcc parser.tab.c lex.yy.c -o parser -lfl
