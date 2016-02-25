
JISON=./node_modules/.bin/jison
ICED=./node_modules/.bin/iced

default: lib/parser.js lib/main.js lib/ast.js

lib/parser.js: src/parser.y src/lexer.l
	${JISON} -o $@ $^
lib/%.js: src/%.iced
	$(ICED) -I node -c -o `dirname $@` $<

test:
	(cd test && iced ./run.iced)

.PHONY: test
