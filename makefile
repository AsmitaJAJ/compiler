all:
	bison -t -d -v /Users/seema/Desktop/compiler/parser.y
	flex /Users/seema/Desktop/compiler/lexer.lex
	


	gcc parser.tab.c lex.yy.c symboltable.c -o parser -L/usr/local/Cellar/flex/2.6.4_2/lib -lfl
