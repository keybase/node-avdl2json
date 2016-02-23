
%s ST_QUOTE2 ST_QUOTE1 ST_COMMENT
%%

<INITIAL>"//".*     /* skip over C++-style comments */

<INITIAL>\s+       /* skip space */

<INITIAL>"record"   return 'RECORD';
<INITIAL>"union"    return 'UNION';
<INITIAL>"enum"     return 'ENUM';
<INITIAL>"protocol" return 'CONTINUE';
<INITIAL>"fixed"    return 'FIXED';
<INITIAL>"string"   return 'STRING';
<INITIAL>"int"      return 'INT';
<INITIAL>"long"     return 'LONG';
<INITIAL>"string"   return 'STRING';
<INITIAL>"boolean"  return 'BOOLEAN';
<INITIAL>"void"     return 'VOID';
<INITIAL>"null"     return 'NULL';

<INITIAL>[a-zA-Z_][a-zA-Z_0-9]* { return 'IDENTIFIER'; }
<INITIAL>[-]?[0-9]*\.[0-9]+ {return 'NUMBER'; }

<INITIAL>"{"        return 'LBRACE';
<INITIAL>"}"        return 'RBRACE';
<INITIAL>"("        return 'LPAREN';
<INITIAL>")"        return 'RPAREN';
<INITIAL>"["        return 'LBRACKET';
<INITIAL>"]"        return 'RBRACKET';
<INITIAL>"<"        return 'LANGLE';
<INITIAL>">"        return 'RANGLE';
<INITIAL>";"        return "SEMICOLON";
<INITIAL>'='        return 'EQUALS';
<INITIAL>'@'        return 'AT_SIGN';

<INITIAL>"\""       { this.begin ('ST_QUOTE2'); return 'QUOTE2'; }
<INITIAL>"'"        { this.begin ('ST_QUOTE1'); return 'QUOTE1'; }
<INITIAL>"/*"       { this.begin ('ST_COMMENT'); }

<INITIAL>[^!./{}()\[\];,:"'\s]+    return 'GENERIC';
<INITIAL>.      return 'GENERIC';

<ST_QUOTE2>"\\".    return 'STRING_FRAG';
<ST_QUOTE2>[^\\"]+  return 'STRING_FRAG';
<ST_QUOTE2>"\""     { this.popState (); return "QUOTE2"; }
<ST_QUOTE2><<EOF>>  return 'EOF';

<ST_QUOTE1>"\\".    return 'STRING_ATOM';
<ST_QUOTE1>[^\\']+  return 'STRING_ATOM';
<ST_QUOTE1>"'"      { this.popState (); return "QUOTE1"; }
<ST_QUOTE1><<EOF>>  return 'EOF';

<ST_COMMENT>"*/"    { this.popState(); }
<ST_COMMENT>"*"     /* ignore */
<ST_COMMENT>[^*]+   /* ignore */
<ST_COMMENT><<EOF>> return 'EOF';
