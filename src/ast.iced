
class Node
  constructor : ( {@start, @end, @decorators} ) ->
  is_import : () -> false
  is_type_decl : () -> false
  decorate : (out) ->
    if @decorators? then (d.decorate(out) for d in @decorators)
    out

class Protocol extends Node
  constructor : ({start, end, @name, @statements, @namespace }) -> super { start, end }
  get_imports : () -> (i for i in @statements when i.is_import())
  get_type_decls : () -> (t for t in @statements when t.is_type_decl())
  get_all_protocols : () -> (i.protocol for i in @get_imports()).concat [ @ ]
  to_json : () ->
    out = { protocol : @name.to_json() }
    out.namespace = @namespace if @namespace
    out.types = []
    for i in @get_all_protocols()
      for t in i.get_type_decls()
        out.types.push t.to_json()
    out

class Decorator extends Node
  constructor : ({start, end, @label, @args }) -> super { start, end }
  decorate : (out) -> out[@label] = @args.to_json()
class Identifier extends Node
  constructor : ({start, end, @name }) -> super { start, end }
  to_json : () -> @name
class Enum extends Node
  constructor : ({start, end, @name, decorators, @constants }) -> super { start, end, decorators }
  is_type_decl : () -> true
  to_json : () -> @decorate { type : "enum", name : @name.to_json(), symbols : (c.to_json() for c in @constants ) }
class Record extends Node
  constructor : ({start, end, decorators, @name, @fields}) -> super { start, end, decorators }
  is_type_decl : () -> true
  to_json : () -> @decorate { type : "record", name : @name.to_json(), fields : (f.to_json() for f in @fields) }
class Field extends Node
  constructor : ({start, end, @type, @name}) -> super { start, end }
  to_json : () -> { type : @type.to_json(), name : @name.to_json() }
class Type extends Node
  constructor : ({start, end, @prim, @custom, @void_type, @null_type }) -> super { start, end }
  to_json : () ->
    if @prim? then @prim
    else if @custom? then @custom.to_json()
    else if @null_type? then "null"
class Value extends Node
  constructor : ({start, end, @int, @string, @bool, @null_value }) -> super { start, end }
  to_json : () ->
    if @string? then @string.eval_to_string()
    else if @int? then @int
    else if @bool? then @bool
    else null
class ArrayType extends Node
  constructor : ({start, end, @type }) -> super { start, end }
  to_json : () -> { type : "array", items : @type.to_json() }
class Union extends Node
  constructor : ({start, end, @types, decorators }) -> super { start, end, decorators }
  is_type_decl : () -> true
  to_json : () -> @decorate (t.to_json() for t in @types)
class Import extends Node
  constructor : ({start, end, @type, @path }) -> super { start, end }
  is_import : () -> true
  set_protocol : (ast) -> @protocol = ast
  get_path : () -> @path
class Message extends Node
  constructor : ({start, end, decorators, @name, @params, @return_type }) -> super { start, end, decorators }
class Param extends Node
  constructor : ({start, end, @type, @name, @def}) -> super { start, end }
class ArrayValue extends Node
  constructor : ({start, end, @type, @name, @def}) -> super { start, end }
class Fixed extends Node
  constructor : ({start, end, @type, @len }) -> super { start, end }
  is_type_decl : () -> true
class String extends Node
  constructor : ({start, end, @type, @val }) -> super { start, end }
  eval_to_string : () -> return JSON.parse @val

module.exports = {
  Protocol, Decorator, Identifier, Enum,
  Record, Field, Type, Value, ArrayType, Union,
  Import, Message, Param, ArrayValue, Fixed, String
}
