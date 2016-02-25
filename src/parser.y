%start Root

%%

Root
  : Protocol {
  return $1;
    }
  ;

Protocol
  : NamespaceOpt PROTOCOL Identifier LBRACE Statements RBRACE { $$ = new yy.Protocol({ start : @1, namespace : $1, name : $3, statements : $5, }); }
  ;

Namespace
  : AT_SIGN NAMESPACE LPAREN String RPAREN { $$ = $4.eval_to_string() }
  ;

NamespaceOpt
  : { $$ = null }
  | Namespace
  ;

Decorators
  : Doc DecoratorList { $$ = new yy.Decorators({start : @1, doc : $1, decorator_list: $2}); }
  ;

DecoratorList
  : { $$ = []; }
  | DecoratorList Decorator {$$ = $1.concat($2) }
  ;

Decorator
  : AT_SIGN Identifier LPAREN Expr RPAREN { $$ = new yy.Decorator({ start: @2, label : $2, args : $4 }); }
  ;

Statements
  : Statement { $$ = [$1]; }
  | Statements Statement { $$ = $1.concat($2); }
  ;

Identifier
  : IDENTIFIER { $$ = new yy.Identifier({start: @1, name : $1 }); }
  ;

Statement
  : Enum
  | Record
  | Message
  | Import
  | Fixed
  ;

Enum
  : Decorators ENUM Identifier LBRACE EnumFields RBRACE { $$ = new yy.Enum({ start: @1, decorators : $1, name : $3, constants : $5 }); }
  ;

EnumFields
  : Identifier { $$ = [ $1 ]; }
  | EnumFields COMMA Identifier { $$ = $1.concat($3) }
  ;

Record
  : Decorators RECORD Identifier LBRACE Fields RBRACE { $$ = new yy.Record({ start: @1, decorators : $1, name : $3, fields : $5 }); }
  ;

Fields
  : { $$ = []; }
  | Fields Field { $$ = $1.concat($2); }
  ;

Field
  : Type Identifier SEMICOLON { $$ = new yy.Field({ start: @1, type : $1, name : $2 }); }
  ;

Type
  : ArrayType
  | Union
  | MapType
  | STRING     { $$ = new yy.Type({start: @1, prim: 'string'  }); }
  | INT        { $$ = new yy.Type({start: @1, prim: 'int'     }); }
  | BOOLEAN    { $$ = new yy.Type({start: @1, prim: 'boolean' }); }
  | LONG       { $$ = new yy.Type({start: @1, prim: 'long'    }); }
  | Identifier { $$ = new yy.Type({start: @1, custom: $1      }); }
  | VOID       { $$ = new yy.Type({start: @1, void_type: true }); }
  ;

TypeOrNull
  : Type
  | NULL { $$ = new yy.Type({ start: @1, null_type : true }); }
  ;

Value
  : String     { $$ = new yy.Value({start: @1, string: $1       }); }
  | NUMBER     { $$ = new yy.Value({start: @1, int: yytext      }); }
  | TRUE       { $$ = new yy.Value({start: @1, bool: true       }); }
  | FALSE      { $$ = new yy.Value({start: @1, bool: false      }); }
  | NULL       { $$ = new yy.Value({start: @1, null_value: true }); }
  ;

ArrayValue
  : LBRACKET Values RBRACKET { $$ = $2; }
  ;

Values
  : Value        { $$ = [$1]; }
  | Values Value { $$ = $1.concat($2); }
  ;

ArrayType
  : ARRAY LANGLE Type RANGLE { $$ = new yy.ArrayType({ start: @1, type : $3 }); }
  ;

MapType
  : MAP LANGLE Type RANGLE { $$ = new yy.MapType({ start: @1, values : $3 }); }
  ;

Union
  : UNION LBRACE TypeOrNullList RBRACE { $$ = new yy.Union({ start: @1, types : $3 }); }
  ;

TypeOrNullList
  : TypeOrNull { $$ = [ $1 ]; }
  | TypeOrNullList COMMA TypeOrNull { $$ = $1.concat($3); }
  ;

Import
  : IMPORT Identifier String SEMICOLON { $$ = new yy.Import({ start: @1, type : $2, path : $3 }); }
  ;

Message
  : Decorators Type Identifier LPAREN ParamsOpt RPAREN SEMICOLON { $$ = new yy.Message({ start: @1, decorators : $1, return_type : $2, name : $3, params : $5 }); }
  ;

ParamsOpt
  : { $$ = [] }
  | Params
  ;

Params
  : Param { $$ = [ $1 ]; }
  | Params COMMA Param { $$ = $1.concat($3); }
  ;

Param
  : Type Identifier ParamDefault { $$ = new yy.Param({ start: @1, type : $1, name : $2, def : $3 }); }
  ;

ParamDefault
  : { $$ = null; }
  | EQUALS Value { $$ = $2; }
  ;

Expr
  : Value
  | ArrayValue { $$ = new yy.ArrayValue({start: @1, values : $1 }); }
  ;

Fixed
  : FIXED Identifier LPAREN NUMBER RPAREN SEMICOLON { $$ = new yy.Fixed({ start: @1, type : $2, len : $4 }); }
  ;

String
  : String1 { $$ = $1; }
  | String2 { $$ = $1; }
  ;

String1
  : QUOTE1 StringFrags QUOTE1 { $$ = new yy.String({start: @1, end: @3, val : "'" + $2 + "'" }); }
  ;

String2
  : QUOTE2 StringFrags QUOTE2 { $$ = new yy.String({start: @1, end:@3, val : '"' + $2 + '"'}); }
  ;

StringFrag
  : STRING_FRAG { $$ = yytext; }
  ;

StringFrags
  : { $$ = ""; }
  | StringFrags STRING_FRAG { $$ = $1 + $2; }
  ;

Doc
  : DocRaw { $$ = new yy.Doc({start : @1, raw: $1 }); }
  ;

DocRaw
  : { $$ = ""; }
  | DocRaw DocFrag { $$ = $1 + $2; }
  ;

DocFrag
  : DOC_FRAG { $$ = yytext; }
  ;
