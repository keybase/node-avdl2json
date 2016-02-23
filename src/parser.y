%start Root

%%

Root
  : Protocol
  ;

Protocol
  : ProtocolName LBRACE Statements RBRACE { $$ = new yy.Protocol ({ loc : @1, label : $1, statements : $3}); }
  ;

ProtocolaName
  : Decorators PROTOCOL Identifier { $$ = new yy.ProtocolName ({ loc : @1, name : $2, decorators : $1 }); }
  ;

Decorators
  : Decorator { $$ = [$1]; }
  | Decorators Decorator { $$ = $1.concat($1) }
  ;

Decorator
  : AT_SIGN Identifier LPAREN Expr RPAREN { $$ = new yy.Decorator({ loc : @2, label : $2, args : $4 }); }
  ;

Statements
  : Statement { $$ = [$1]; }
  | Statements Statement { $$ = $1.concat($2); }
  ;

Identifier
  : IDENTIFIER { $$ = new yy.Identifier({loc : @1, name : $1 }); }
  ;

Statement
  : Enum
  | Record
  | Message
  | Import
  | Fixed
  ;

Enum
  : Decorators ENUM Identifier LBRACE EnumFields RBRACE { $$ = new yy.Enum({ loc : @1, decorators : $1, name : $3, constants : $5 }); }
  ;

EnumFields
  : Identifier { $$ = [ $1 ]; }
  | EnumConstants COMMA Identifier { $$ = $1.concat($2) }
  ;

Record
  : Decorators RECORD Identifier LBRACE Fields RBRACE { $$ = new yy.Record({ loc : @1, decorators : $1, name : $3, fields : $5 }); }
  ;

Fields
  : Field { $$ = [ $1 ]; }
  | Fields Field { $$ = $1.concat($2); }
  ;

Field
  : Type Identifier SEMICOLON { $$ = new yy.Field({ loc : @1, type : $1, name : $2 }); }
  ;

Type
  : Array
  | Union
  | STRING     { $$ = new yy.Type({loc: @1, string: true     }); }
  | INT        { $$ = new yy.Type({loc: @1, int: true        }); }
  | BOOLEAN    { $$ = new yy.Type({loc: @1, bool: true       }); }
  | LONG       { $$ = new yy.Type({loc: @1, long: true       }); }
  | Identifier { $$ = new yy.Type({loc: @1, custom: $1       }); }
  | VOID       { $$ = new yy.Type({loc: @1, void_type: true  }); }
  ;

TypeOrNull
  : Type
  | NULL { new yy.Type({ loc : @1, null_type : true }); }
  ;

Value
  : STRING_TOK { $$ = new yy.Value({loc: @1, string: yytext   }); }
  | NUMBER     { $$ = new yy.Value({loc: @1, int: yytext      }); }
  | TRUE       { $$ = new yy.Value({loc: @1, bool: true       }); }
  | FALSE      { $$ = new yy.Value({loc: @1, bool: false      }); }
  | NULL       { $$ = new yy.Value({loc: @1, null_value: true }); }
  ;

ArrayOfValues
  | LBRACKET Values RBRACKET { $$ = $2 }
  ;

Values
  : Value   { $$ = [$1]; }
  | Values  { $$ = $1.concat($2); }
  ;

Array
  : ARRAY LANGLE Type RANGLE { $$ = new yy.Array({ loc: @1, type : $3 }); }
  ;

Union
  : UNION LBRACE TypeOrNullList RBRACE { $$ = new yy.Union({ loc : @1, types : $3 }); }
  ;

TypeOrNullList
  : TypeOrNull { $$ = [ $1 ]; }
  | TypeOrNullList COMMA TypeOrNull { $$ = $1.concat($2);
  ;

Import
  : IMPORT Identifier STRING_TOK { $$ = new yy.Import({ loc : @1, type : $2, path : $3 }); }
  ;

Message
  : Decorators Type Identifier LPAREN Params RPAREN SEMICOLON { $$ = new yy.Message({ loc: @1, decorators : $1, returns : $2, name : $3, params : $5 }); }
  ;

Params
  : Param { $$ = [ $1 ]; }
  | Params COMMA Param { $$ = $1.concat($2); }
  ;

Param
  : Type Identifier ParamDefault { $$ = new yy.Param({ loc: @1, type : $1, name : $2, def : $3 }); }
  ;

ParamDefault
  : { $$ = null; }
  | EQUALS Value { return new yy.Value({loc: @1, value : $2 }); }
  ;

Expr
  : Value
  | ArrayOfValues { $$ = new yy.ValueArray({loc: @1, values : $1 }); }
  ;

Fixed
  : FIXED Identifier LPAREN NUMBER RPAREN SEMICOLON { $$ = new yy.Fixed({ loc : @1, type : $2, len : $4 }); }
  ;
