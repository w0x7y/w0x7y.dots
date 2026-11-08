-- Revo, by hand since vis can't use tree-sitter-revo. Keywords match Revo's lexer

local lexer = lexer
local B, P, S = lpeg.B, lpeg.P, lpeg.S

local lex = lexer.new(...)

local ws = lex:tag(lexer.WHITESPACE, lexer.space^1)

-- Comments: # to the end of the line, #* block *#, and the #! shebang block !#
local block = lexer.range('#*', '*#')
local shebang = lexer.starts_line('#!') * (1 - P('!#'))^0 * P('!#')^-1
lex:add_rule('comment', lex:tag(lexer.COMMENT, shebang + block + lexer.to_eol('#')))

-- fn name, fn Type.new, fn Type:method
lex:add_rule('function_def', lex:tag(lexer.KEYWORD, 'fn') * ws
	* lex:tag(lexer.FUNCTION, lexer.word * (S('.:') * lexer.word)^0))

-- Labelled blocks: do/b, loop/l, break/b(value)
lex:add_rule('label', lex:tag(lexer.KEYWORD, lexer.word_match{ 'do', 'loop', 'break' })
	* lex:tag(lexer.OPERATOR, '/') * lex:tag(lexer.LABEL, lexer.word))

lex:add_rule('keyword', lex:tag(lexer.KEYWORD, lexer.word_match{
	'const', 'global', 'let', 'comp', 'test', 'suite', 'type', 'fn', 'if', 'unless', 'else',
	'match', 'when', 'do', 'end', 'loop', 'for', 'while', 'in', 'break', 'continue', 'return',
	'spawn', 'yield', 'and', 'or', 'not', 'band', 'bor', 'bxor', 'shl', 'shr', 'orelse', 'pub',
	'declare', 'import', 'use',
}))

lex:add_rule('constant', lex:tag(lexer.CONSTANT_BUILTIN, lexer.word_match{ 'true', 'false', 'nil' }))

-- Atoms: :ok, {:err, :NoData}. Not xs:len(), a method call
lex:add_rule('atom', lex:tag(lexer.STRING .. '.symbol',
	B(1 - (lexer.alnum + S('_:)]}"'))) * ':' * lexer.word))

lex:add_rule('builtin', lex:tag(lexer.FUNCTION_BUILTIN, lexer.word_match{
	'print', 'panic', 'join', 'set_meta', 'expect', 'expect_eq', 'self',
}))
lex:add_rule('function', lex:tag(lexer.FUNCTION, lexer.word) * #(P('!')^-1 * '('))

lex:add_rule('type', lex:tag(lexer.TYPE, lexer.upper * (lexer.alnum + '_')^0))

lex:add_rule('identifier', lex:tag(lexer.IDENTIFIER, lexer.word))
lex:add_rule('string', lex:tag(lexer.STRING, lexer.range('"')))
lex:add_rule('number', lex:tag(lexer.NUMBER, lexer.number))
lex:add_rule('operator', lex:tag(lexer.OPERATOR, S('+-*/%=<>!?|&.,:;(){}[]^~')))

return lex
