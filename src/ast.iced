
class Node
  constructor : ( {@start, @end} ) ->
class Protocol extends Node
  constructor : ({start, end, @label, @statements }) -> super { start, end }
class ProtocolName extends Node
  constructor : ({start, end, @name, @decorators}) -> super { start, end }
class Decorator extends Node
  constructor : ({start, end, @label, @args }) -> super { start, end }
class Identifier extends Node
  constructor : ({start, end, @name }) -> super { start, end }
class Enum extends Node
  constructor : ({start, end, @decorators, @constants }) -> super { start, end }
class Record extends Node
  constructor : ({start, end, @decorators, @name, @fields}) -> super { start, end }
class Field extends Node
  constructor : ({start, end, @type, @name}) -> super { start, end }
class Type extends Node
  constructor : ({start, end, @string, @int, @bool, @long, @custom, @void_type, @null_type }) -> super { start, end }
class Value extends Node
  constructor : ({start, end, @int, @string, @bool, @null_value }) -> super { start, end }
class ArrayType extends Node
  constructor : ({start, end, @type }) -> super { start, end }
class Union extends Node
  constructor : ({start, end, @types }) -> super { start, end }
class Import extends Node
  constructor : ({start, end, @type, @path }) -> super { start, end }
class Message extends Node
  constructor : ({start, end, @decorators, @name, @params, @return_type }) -> super { start, end }
class Param extends Node
  constructor : ({start, end, @type, @name, @def}) -> super { start, end }
class ArrayValue extends Node
  constructor : ({start, end, @type, @name, @def}) -> super { start, end }
class Fixed extends Node
  constructor : ({start, end, @type, @len }) -> super { start, end }
class String extends Node
  constructor : ({start, end, @type, @val }) -> super { start, end }

module.exports = {
  Protocol, ProtocolName, Decorator, Identifier, Enum,
  Record, Field, Type, Value, ArrayType, Union,
  Import, Message, Param, ArrayValue, Fixed, String
}
