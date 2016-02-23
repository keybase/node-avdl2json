
{Parser} = require 'jison'

#
# DSL taken from CoffeeScript's grammar.coffee
#
o = (patternString, action, options) ->
  patternString = patternString.replace /\s{2,}/g, ' '
  patternCount = patternString.split(' ').length
  return [patternString, '$$ = $1;', options] unless action
  action = "(#{action}())"

  # All runtime functions we need are defined on "yy"
  action = action.replace /\bnew /g, '$&yy.'
  action = action.replace /\b(?:Block\.wrap|extend)\b/g, 'yy.$&'

  # Returns a function which adds location data to the first parameter passed
  # in, and returns the parameter.  If the parameter is not a node, it will
  # just be passed through unaffected.
  addLocationDataFn = (first, last) ->
    if not last
      "yy.addLocationDataFn(@#{first})"
    else
      "yy.addLocationDataFn(@#{first}, @#{last})"

  action = action.replace /LOC\(([0-9]*)\)/g, addLocationDataFn('$1')
  action = action.replace /LOC\(([0-9]*),\s*([0-9]*)\)/g, addLocationDataFn('$1', '$2')

  [patternString, "$$ = #{addLocationDataFn(1, patternCount)}(#{action});", options]

# Grammatical Rules
grammar =

  Root : [
    o 'Protocol'
  ]

  Protocol : [
    o 'ProtocolLabel { Statements }',     -> new Protocol { label : $1, statements : $3 }
  ]

  ProtocolLabel : [
    o 'Decorators Identifier',            -> new ProtocolLabel { name : $2, decorators : $1 }
  ]

  Decorators : [
    o 'Decorator'
    o 'Decorators Decorator',             -> $1.concat $2
  ]

  Decorator :   [
    o '@ Identifier ( Expr )',            -> new Decorator { label : $2, args : $4 }
  ]

  Statements : [
    o 'Statement'
    o 'Statements Statement',             -> $1.concat $2
  ]

  Identifier : [
    o 'IDENTIFIER',                         -> new Identifier $1
  ]

  Statement : [
    o 'Enum'
    o 'Record'
    o 'Message'
    o 'Import'
    o 'Fixed'
  ]

  Enum : [
    o 'Decorators ENUM Identifier { EnumConstants }', -> new Enum { decorators : $1, name : $3, constants : $5 }
  ]

  EnumConstants : [
    o 'Identifier',                       -> [ $1 ]
    o 'EnumConstants , Identifier',       -> $1.concat $2
  ]

  Record : [
    o 'Decorators RECORD Identifier { Fields }',      -> new Record { decorators : $1, name : $3, fields : $5 }
  ]

  Fields : [
    o 'Field',                          -> [ $1 ]
    o 'Fields Field',                   -> $1.concat $2
  ]

  Field : [
    o 'Type Identifier ;',              -> new Field { type : $1, name : $2 }
  ]

  Type : [
    o 'Array'
    o 'Union'
    o 'STRING'
    o 'INT'
    o 'BOOLEAN'
    o 'LONG'
    o 'Identifier'
    o 'VOID'
  ]

  TypeOrNull : [
    o 'Type'
    o 'NULL',                           -> new Type { null_type : true }
  ]

  Value : [
    o 'STRING_TOK'
    o 'NUMBER'
    o 'TRUE'
    o 'FALSE'
    o 'NULL'
  ]

  ArrayOfValues : [
    o '[ Values ]'
  ]

  Values : [
    o 'Value',                          -> [$1]
    o 'Values , Value',                 -> $1.concat $2
  ]

  Array : [
    o 'ARRAY < Type > ',                -> new Array { type : $3 }
  ]

  Union : [
    o 'UNION { TypeOrNullList }',       -> new Union { types : $3 }
  ]

  TypeOrNullList : [
    o 'TypeOrNull',                     -> [ $1 ]
    o 'TypeOrNullList , TypeOrNull',    -> $1.concat $2
  ]

  Import : [
    o 'IMPORT Identifier STRING_TOK',   -> new Import { type : $2, path : $3 }
  ]

  Message : [
    o 'Decorators Type Identifier ( Params ) ;', -> new Message { decorators : $1, returns : $2, name : $3, params : $5 }
  ]

  Params : [
    o 'Param',                          -> [ $1 ]
    o 'Params , Param',                 -> $1.concat $2
  ]

  Param : [
    o 'Type Identifier ParamDefault',   -> new Param { type : $1, name : $2, def : $3 }
  ]

  ParamDefault : [
    o '',                               -> null
    o '= Value',                        -> new Value $2
  ]

  Expr : [
    o 'Value'
    o 'ArrayOfValues'
  ]

  Fixed : [
    o 'FIXED Identifier ( NUMBER ) ;',  -> new Fixed { type : $2, len : $4 }
  ]

# Lexer
keywords = [ 'record', 'int', 'string', 'null', 'record', 'enum', 'true', 'false', 'void', 'long', 'import', 'array' ]

make_keyword = (w) -> [ w, (-> w.toUpperCase()).toString() ]
make_keywords = (v) -> (make_keyword(w) for w in v)

lex =
  rules : [
    ["//.*", -> '' ]
  ]



  ]make_keywords(keywords).concat [
    [ '/\d+/', new ]

  ]

# Put precedence rules here
operators = []

# Wrapping Up
# -----------

# Finally, now that we have our **grammar** and our **operators**, we can create
# our **Jison.Parser**. We do this by processing all of our rules, recording all
# terminals (every symbol which does not appear as the name of a rule above)
# as "tokens".
tokens = []
for name, alternatives of grammar
  grammar[name] = for alt in alternatives
    for token in alt[0].split ' '
      tokens.push token unless grammar[token]
    alt[1] = "return #{alt[1]}" if name is 'Root'
    alt

# Initialize the **Parser** with our list of terminal **tokens**, our **grammar**
# rules, and the name of the root. Reverse the operators because Jison orders
# precedence from low to high, and we have it high to low
# (as in [Yacc](http://dinosaur.compilertools.net/yacc/index.html)).
exports.parser = new Parser
  tokens      : tokens.join ' '
  bnf         : grammar
  operators   : operators.reverse()
  startSymbol : 'Root'

console.log tokens
grammar = exports.parser.generate()
