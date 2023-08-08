% See https://www.erlang.org/doc/man/yecc

% From `Pre-Processing` section:
%
%   The user should implement a scanner that segments the input text, and turns
%   it into one or more lists of tokens. Each token should be a tuple
%   containing information about syntactic category, position in the text (e.g.
%   line number), and the actual terminal symbol found in the text:
%
%       {Category, Position, Symbol}.
%
%   If a terminal symbol is the only member of a category, and the symbol name
%   is identical to the category name, the token format may be
%
%       {Symbol, Position}.

Nonterminals
  root
  statement
  statements
  variables
  expr
  app
  infix
.

Terminals
  number
  identifier
  '+' '-' '*' '/'
  '(' ')'
  '{' '}'
  '=' ';'
  'fn' ',' '=>'
.

Rootsymbol
   root
.

Left 300 '+'.
Left 300 '-'.
Left 400 '*'.
Left 400 '/'.

root -> statements                          : '$1'.

statements  -> statement                    : ['$1'].
statements  -> statement ';' statements     : ['$1' | '$3'].

statement -> identifier '=' expr            : {assign, unwrap('$1'), '$3'}.
statement -> expr                           : '$1'.

variables -> identifier                     : [unwrap('$1')].
variables -> identifier ',' variables       : [unwrap('$1') | '$3'].

expr -> fn variables '=>' expr              : {fn, '$2', '$4'}.
expr -> fn variables '=>' '{' statement '}' : {fn, '$2', '$5'}.
expr -> app                                 : '$1'.
app  -> app infix                           : {application, '$1', '$2'}.
app  -> infix                               : '$1'.
infix -> number                             : unwrap('$1').
infix -> identifier                         : unwrap('$1').
infix -> infix '+' infix                    : {add_op, '$1', '$3'}.
infix -> infix '-' infix                    : {sub_op, '$1', '$3'}.
infix -> infix '*' infix                    : {mul_op, '$1', '$3'}.
infix -> infix '/' infix                    : {div_op, '$1', '$3'}.
infix -> '(' expr ')'                       : '$2'.

Erlang code.

unwrap({Type, Line, Value}) -> {Type, Line, Value}.
% unwrap({number, _Line, Value}) -> list_to_integer(Value);
% unwrap({identifier, _Line, Value}) -> list_to_binary(Value).
