
#=======================================================================

class Node
  constructor : ( {@start, @end, @decorators} ) ->
  is_import : () -> false
  is_type_decl : () -> false
  is_message : () -> false
  decorate : (out) -> if @decorators? then @decorators.decorate(out) else out

#=======================================================================

class ProtocolBase extends Node
  constructor : ({start, end, @name, @statements, decorators }) -> super { start, end, decorators }
  get_imports : () -> (i for i in @statements when i.is_import())
  get_type_decls : () -> (t for t in @statements when t.is_type_decl())
  get_all_messages : () -> (m for m in @statements when m.is_message())
  has_messages : () -> @get_all_messages().length > 0
  to_json : () ->
    out = { protocol : @name.to_json() }
    @output_imports(out)
    out.types = []
    for i in @get_protocols_for_output_types()
      for t in i.get_type_decls()
        out.types.push t.to_json()
    out.messages = {}
    for m in @get_all_messages()
      m.to_json out.messages
    @decorate out
  get_all_protocols : (seen) ->
    ret = [ ]
    seen or= {}
    for i in @get_imports() when not seen[nm = i.path.eval_to_string()]
      seen[nm] = true
      for p in i.protocol.get_all_protocols(seen)
        ret.push p
    ret.push @
    ret

#=======================================================================

class Protocol extends ProtocolBase
  get_protocols_for_output_types : () -> @get_all_protocols()
  output_imports : (out) -> out

#=======================================================================

class ProtocolV2 extends ProtocolBase
  get_protocols_for_output_types : () -> [ @ ]
  output_imports : (out) ->
    out.imports = (i.to_json() for i in @get_imports())
    out

#=======================================================================

class Decorator extends Node
  constructor : ({start, end, @label, @args }) -> super { start, end }
  decorate : (out) -> out[@label.to_json()] = @args.to_json()

#=======================================================================

class Decorators extends Node
  constructor : ({start, end, @doc, @decorator_list}) ->
    super { start, end }
  decorate : (out) ->
    out.doc = d if (d = @doc.get_doc_string())?
    (d.decorate(out) for d in @decorator_list)
    out

#=======================================================================

class Identifier extends Node
  constructor : ({start, end, @name }) -> super { start, end }
  to_json : () -> @name
  dot : (n2) -> @name = @name + "." + n2.name

#=======================================================================

class Enum extends Node
  constructor : ({start, end, @name, decorators, @constants }) -> super { start, end, decorators }
  is_type_decl : () -> true
  to_json : () -> @decorate { type : "enum", name : @name.to_json(), symbols : (c.to_json() for c in @constants ) }

#=======================================================================

class Record extends Node
  constructor : ({start, end, decorators, @name, @fields}) -> super { start, end, decorators }
  is_type_decl : () -> true
  to_json : () -> @decorate { type : "record", name : @name.to_json(), fields : (f.to_json() for f in @fields) }

#=======================================================================

class Field extends Node
  constructor : ({start, end, @type, @name, decorators}) -> super { start, end, decorators }
  to_json : () ->
    @decorate { type : @type.to_json(), name : @name.to_json() }

#=======================================================================

class TypeBase extends Node
  constructor : ({start, end, @prim, @custom, @void_type, @null_type }) -> super { start, end }
  to_json : () ->
    if @prim? then @prim
    else if @custom? then @custom.to_json()
    else if @null_type? then @null_value()
    else if @void_type then @null_value()

#=======================================================================

class Type extends TypeBase
  null_value : () -> "null"
class TypeV2 extends TypeBase
  null_value : () -> null

#=======================================================================

class Value extends Node
  constructor : ({start, end, @int, @string, @bool, @null_value }) -> super { start, end }
  to_json : () ->
    if @string? then @string.eval_to_string()
    else if @int? then @int
    else if @bool? then @bool
    else null

#=======================================================================

class ArrayType extends Node
  constructor : ({start, end, @type }) -> super { start, end }
  to_json : () -> { type : "array", items : @type.to_json() }

#=======================================================================

class MapType extends Node
  constructor : ({start, end, @values }) -> super { start, end }
  to_json : () -> { type : "map", values : @values.to_json() }

#=======================================================================

class Union extends Node
  constructor : ({start, end, @types, decorators }) -> super { start, end, decorators }
  is_type_decl : () -> true
  to_json : () -> @decorate (t.to_json() for t in @types)

#=======================================================================

class Import extends Node
  constructor : ({start, end, @type, @path, @import_as }) -> super { start, end }
  is_import : () -> true
  set_protocol : (ast) -> @protocol = ast
  get_path : () -> @path
  to_json : () ->
    out = {}
    if @path? then out.path = @path.eval_to_string()
    if @type? then out.type = @type.to_json()
    if @import_as? then out.import_as = @import_as.to_json()
    return out

#=======================================================================

class Message extends Node
  constructor : ({start, end, decorators, @name, @params, @return_type, @oneway }) -> super { start, end, decorators }
  is_message : () -> true
  to_json : (out) ->
    msg = {
      request : (p.to_json() for p in @params)
      response : @return_type.to_json()
    }
    if @oneway then msg.oneway = true
    out[@name.to_json()] = @decorate msg
    return out

#=======================================================================

class Param extends Node
  constructor : ({start, end, @type, @name, @def}) -> super { start, end }
  to_json : () ->
    out = { name : @name.to_json(), type : @type.to_json() }
    if @def? then out.default = @def.to_json()
    return out

#=======================================================================

class ArrayValue extends Node
  constructor : ({start, end, @type, @name, @def}) -> super { start, end }

#=======================================================================

class Fixed extends Node
  constructor : ({start, end, @type, @len }) -> super { start, end }
  is_type_decl : () -> true
  to_json : () -> @decorate { type : "fixed", name : @type.to_json(), size : @len }

#=======================================================================

class String extends Node
  constructor : ({start, end, @type, @val }) -> super { start, end }
  eval_to_string : () -> return JSON.parse @val

#=======================================================================

class Doc extends Node
  constructor : ( {start, end, raw} ) ->
    super { start, end }
    @doc = raw.trim()
  get_doc_string : () -> if @doc.length then @doc else null

#=======================================================================

module.exports = {
  Protocol, Decorator, Identifier, Enum, Decorators,
  Record, Field, Type, Value, ArrayType, Union,
  Import, Message, Param, ArrayValue, Fixed, String, Doc,
  MapType, ProtocolV2, TypeV2
}
