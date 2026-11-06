-- Rime, soft muted pastels: a port of https://github.com/w0x7y/rime v0.5.1

local lexers = vis.lexers

-- themes/rime-frost.lua loads this file under its name for the light palette
local palettes = {
	rime = {
		bg        = '#23272e', -- base00
		bg_alt    = '#2b3038', -- base01
		bg_sel    = '#3a404b', -- base02
		comment   = '#6b768c', -- base03
		muted     = '#9aa4b6', -- base04
		fg        = '#c3ccd9', -- base05
		fg_bright = '#dce2eb', -- base06
		white     = '#f0f3f8', -- base07
		red       = '#d98a9c', -- base08
		pink      = '#e8a8cc', -- base09
		yellow    = '#e4d098', -- base0A
		green     = '#9ad8ac', -- base0B
		cyan      = '#7cc4d0', -- base0C
		blue      = '#7aa4e4', -- base0D
		violet    = '#bb98d6', -- base0E
		steel     = '#7987a1', -- base0F
	},
	['rime-frost'] = {
		bg        = '#eef1f5', -- base00
		bg_alt    = '#e3e7ee', -- base01
		bg_sel    = '#d2d8e2', -- base02
		comment   = '#7f899b', -- base03
		muted     = '#566073', -- base04
		fg        = '#363d4a', -- base05
		fg_bright = '#272d37', -- base06
		white     = '#181c23', -- base07
		red       = '#b83d63', -- base08
		pink      = '#a34396', -- base09
		yellow    = '#866405', -- base0A
		green     = '#267b4f', -- base0B
		cyan      = '#0f7480', -- base0C
		blue      = '#2e62c0', -- base0D
		violet    = '#7650c4', -- base0E
		steel     = '#5f7090', -- base0F
	},
}
local c = palettes[tostring(... or ''):match('rime%-frost$') and 'rime-frost' or 'rime']

-- Blends a towards b by t, rounding half up, as rime does
local function mix(a, b, t)
	local out = '#'
	for i = 2, 6, 2 do
		local x, y = tonumber(a:sub(i, i + 1), 16), tonumber(b:sub(i, i + 1), 16)
		out = out .. string.format('%02x', math.floor(x + (y - x) * t + 0.5))
	end
	return out
end
c.border      = mix(c.bg_alt, c.bg_sel, 0.5)
c.colorcolumn = mix(c.bg, c.bg_alt, 0.5)
c.whitespace  = mix(c.comment, c.bg, 0.45)
c.diff_delete = mix(c.red, c.bg, 0.85)
c.diag_error  = mix(c.red, c.bg, 0.9)
c.diag_warn   = mix(c.yellow, c.bg, 0.9)
c.diag_info   = mix(c.blue, c.bg, 0.9)
c.diag_hint   = mix(c.cyan, c.bg, 0.9)
c.git_add     = mix(c.green, c.bg, 0.8)
c.git_change  = mix(c.blue, c.bg, 0.68)
c.git_removed = mix(c.red, c.bg, 0.55)

local function fg(name, attrs)
	return 'fore:' .. c[name] .. (attrs and ',' .. attrs or '')
end

-- Colors that let a tint keep the syntax color under it: 'default' on later vis.
-- vis 0.9 keeps only its default colors, white and black when it redefines the palette
local keep_fg, keep_bg = 'default', 'default'
local vis09 = not vis.ui.style_push -- later vis keeps styles in vis.ui
if vis09 and vis.options.changecolors and os.execute('tput ccc >/dev/null 2>&1') then
	local tput = io.popen('tput colors 2>/dev/null')
	local colors = tput and tonumber(tput:read('l') or '')
	if tput then tput:close() end
	if colors and colors >= 256 then
		keep_fg, keep_bg = 'white', 'black'
	end
end

-- An unstyled sub-tag (heading.h1) takes its parent's style, as in Scintillua
if not getmetatable(lexers) then
	setmetatable(lexers, {__index = function(t, k)
		local parent = type(k) == 'string' and k:match('^(STYLE_.+)_[^_]+$')
		if parent then return t[parent] end
	end})
end

-- editor UI
lexers.STYLE_DEFAULT = 'fore:' .. c.fg .. ',back:' .. c.bg
lexers.STYLE_NOTHING = 'back:' .. c.bg
lexers.STYLE_CURSOR = 'fore:' .. c.bg .. ',back:' .. c.muted -- secondary cursors
lexers.STYLE_CURSOR_PRIMARY = 'fore:' .. c.bg .. ',back:' .. c.fg
lexers.STYLE_CURSOR_LINE = 'back:' .. c.bg_alt
-- keep_attribute: comments stay italic under these tints (later vis; 0.9 ignores it)
lexers.STYLE_COLOR_COLUMN = 'back:' .. c.colorcolumn .. ',keep_attribute'
lexers.STYLE_SELECTION = 'back:' .. c.bg_sel .. ',keep_attribute'
lexers.STYLE_LINENUMBER = fg('comment')
lexers.STYLE_LINENUMBER_CURSOR = fg('fg_bright', 'bold')
lexers.STYLE_STATUS = 'fore:' .. c.comment .. ',back:' .. c.bg_alt
lexers.STYLE_STATUS_FOCUSED = 'fore:' .. c.muted .. ',back:' .. c.bg_alt
lexers.STYLE_SEPARATOR = fg('border')
lexers.STYLE_INFO = fg('fg')
lexers.STYLE_EOF = fg('bg_sel')
lexers.STYLE_WHITESPACE = fg('whitespace')

-- syntax (vis tag -> rime syntax role)
lexers.STYLE_COMMENT = fg('comment', 'italics')
lexers.STYLE_STRING = fg('green')
lexers.STYLE_NUMBER = fg('pink')
lexers.STYLE_KEYWORD = fg('violet') -- vis has one keyword tag, so if/for/return too
lexers.STYLE_IDENTIFIER = fg('fg') -- variable
lexers.STYLE_OPERATOR = fg('muted')
lexers.STYLE_ERROR = fg('red')
lexers.STYLE_PREPROCESSOR = fg('yellow') -- keyword.directive
lexers.STYLE_CONSTANT = fg('pink')
lexers.STYLE_CONSTANT_BUILTIN = fg('cyan')
lexers.STYLE_VARIABLE = fg('fg')
lexers.STYLE_VARIABLE_BUILTIN = fg('cyan')
lexers.STYLE_FUNCTION = fg('blue')
lexers.STYLE_FUNCTION_BUILTIN = fg('cyan')
lexers.STYLE_CLASS = fg('yellow') -- type
lexers.STYLE_TYPE = fg('yellow')
lexers.STYLE_LABEL = fg('yellow')
lexers.STYLE_REGEX = fg('cyan') -- string.regexp
lexers.STYLE_EMBEDDED = fg('cyan') -- punctuation.special
lexers.STYLE_TAG = fg('red')
lexers.STYLE_TAG_CHARS = fg('steel') -- punctuation: < > />
lexers.STYLE_ATTRIBUTE = fg('yellow') -- tag.attribute
lexers.STYLE_ANNOTATION = fg('cyan') -- attribute: decorators, annotations
lexers.STYLE_STRING_SYMBOL = fg('pink') -- string.special.symbol

-- markup
lexers.STYLE_HEADING = fg('blue', 'bold') -- markup.heading
lexers.STYLE_BOLD = 'bold' -- markup.strong
lexers.STYLE_ITALIC = 'italics' -- markup.italic
lexers.STYLE_UNDERLINE = 'underlined'
lexers.STYLE_CODE = fg('green') -- markup.raw
lexers.STYLE_LINK = fg('blue', 'underlined') -- markup.link.url
lexers.STYLE_REFERENCE = fg('cyan') -- markup.link.label
lexers.STYLE_LIST = fg('red') -- markup.list
lexers.STYLE_HR = fg('comment')

-- lexer specific
lexers.STYLE_ADDITION = fg('green') -- diff.plus
lexers.STYLE_DELETION = fg('red') -- diff.minus
lexers.STYLE_CHANGE = fg('blue') -- diff.delta
lexers.STYLE_PROPERTY = fg('red') -- property: CSS keys
lexers.STYLE_PSEUDOCLASS = fg('violet') -- selector.pseudo
lexers.STYLE_PSEUDOELEMENT = fg('violet') -- selector.pseudo
lexers.STYLE_TAG_UNKNOWN = fg('red', 'italics')
lexers.STYLE_ATTRIBUTE_UNKNOWN = fg('yellow', 'italics')
lexers.STYLE_COMMAND = fg('violet') -- LaTeX
lexers.STYLE_COMMAND_SECTION = fg('blue', 'bold')
lexers.STYLE_ENVIRONMENT = fg('yellow')
lexers.STYLE_ENVIRONMENT_MATH = fg('pink')
lexers.STYLE_ERROR_INDENT = 'back:' .. c.diff_delete -- YAML
lexers.STYLE_FILENAME = fg('blue') -- compiler output
lexers.STYLE_LINE = fg('pink')
lexers.STYLE_COLUMN = fg('pink')
lexers.STYLE_MESSAGE = fg('fg')
lexers.STYLE_TAG_DAY = fg('yellow') -- Taskpaper

-- The plugins' colors. Themes load after the plugins; delete this part to keep theirs

-- vis-modal, like rime's lualine theme. STYLES is edited in place: modal holds a reference
local modal = package.loaded['plugins/vis-modal']
if modal then
	local function mode(accent)
		return 'fore:' .. c.bg .. ',back:' .. c[accent] .. ',bold', 'fore:' .. c[accent] .. ',back:' .. c.bg_sel
	end
	for m, accent in pairs({
		[vis.modes.NORMAL] = 'blue',
		[vis.modes.INSERT] = 'green',
		[vis.modes.VISUAL] = 'violet',
		[vis.modes.VISUAL_LINE] = 'violet',
		[vis.modes.REPLACE] = 'red',
		[vis.modes.OPERATOR_PENDING] = 'yellow',
	}) do
		modal.STYLES[m].REGULAR, modal.STYLES[m].INVERTED = mode(accent)
	end
	local inactive = 'fore:' .. c.comment .. ',back:' .. c.bg_alt
	modal.STYLES.UNFOCUSED.REGULAR, modal.STYLES.UNFOCUSED.INVERTED = inactive, inactive
end

-- vis-lspc: problems underlined in their color, over any git tint
local lspc = package.loaded['plugins/vis-lspc']
if lspc then
	for severity, color in pairs({error = 'red', warning = 'yellow', information = 'blue', hint = 'cyan'}) do
		lspc.diagnostic_styles[severity] = fg(color, 'underlined,back:' .. keep_bg)
	end
end

-- config/diagnostics.lua, like rime's diagnostic virtual text
local diagnostics = package.loaded['config/diagnostics']
if diagnostics then
	local severities = {{'red', c.diag_error}, {'yellow', c.diag_warn}, {'blue', c.diag_info}, {'cyan', c.diag_hint}}
	for s, colors in ipairs(severities) do
		diagnostics.styles.message[s] = fg(colors[1]) .. ',back:' .. colors[2]
		diagnostics.styles.count[s] = fg(colors[1]) .. ',back:' .. c.bg_sel
	end
	diagnostics.styles.gap = 'back:' .. c.bg_sel
end

-- vis-gitsigns: tints that keep the code's colors
local gitsigns = package.loaded['plugins/vis-gitsigns']
if gitsigns then
	gitsigns.styles.add = 'fore:' .. keep_fg .. ',back:' .. c.git_add
	gitsigns.styles.change = 'fore:' .. keep_fg .. ',back:' .. c.git_change
	gitsigns.styles.cut = 'fore:' .. keep_fg .. ',back:' .. c.git_removed
	gitsigns.styles.removed = fg('fg_bright', 'back:' .. c.git_removed)
end

-- vis-oil: folders in blue
local oil = package.loaded['plugins/vis-oil']
if oil then
	oil.styles.dir = fg('blue')
end
