% See https://www.erlang.org/doc/man/leex.html

Definitions.

NUMBER     = [0-9]+
IDENTIFIER = [a-zA-Z_][a-zA-Z0-9_]*
WHITESPACE = [\s\t\n\r]

Rules.

\+            : {token, {'+',        TokenLine}}.
\*            : {token, {'*',        TokenLine}}.
\(            : {token, {'(',        TokenLine}}.
\)            : {token, {')',        TokenLine}}.
-             : {token, {'-',        TokenLine}}.
/             : {token, {'/',        TokenLine}}.
=             : {token, {'=',        TokenLine}}.
;             : {token, {';',        TokenLine}}.
,             : {token, {',',        TokenLine}}.
fn            : {token, {fn,         TokenLine}}.
=>            : {token, {'=>',       TokenLine}}.
{NUMBER}      : {token, {number,     TokenLine, TokenChars}}.
{IDENTIFIER}  : {token, {identifier, TokenLine, TokenChars}}.
{WHITESPACE}+ : skip_token.

Erlang code.
