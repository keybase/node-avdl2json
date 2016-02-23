
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
    o '@ Identifier ( expr )',            -> new Decorator { label : $2, args : $4 }
  ]

  Statements : [
    o 'Statement'
    o 'Statements Statement',             -> $1.concat $2
  ]

  Identifier : [
    'IDENTIFIER',                         -> new Identifier $1
  ]

  Statement : [
    o 'Enum'
    o 'Record'
    o 'Message'
    o 'Import'
    o 'Fixed'
  ]

console.log grammar
