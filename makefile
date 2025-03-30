all:
	bison -t -d -v C:/Users/HP/Downloads/compiler-main/parser.y
	flex C:/Users/HP/Downloads/compiler-main/lexer.lex
	
	gcc parser.tab.c lex.yy.c symboltable.c -o mycomp -L/usr/local/Cellar/flex/2.6.4_2/lib -lfl

	
	flex -d lexer.lex
	bison -t -d -v parser.y
	gcc -o mycomp.exe symboltable.c parser.tab.c lex.yy.c -lfl