
JISON=./node_modules/.bin/jison

default: lib/parser.js

lib/parser.js: src/parser.y src/lexer.l
	${JISON} -o $@ $^
