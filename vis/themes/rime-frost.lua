-- Rime Frost, rime's light variant: themes/rime.lua loaded under this name
local dir = debug.getinfo(1, 'S').source:sub(2):match('(.*/)')
return assert(loadfile(dir .. 'rime.lua'))('themes/rime-frost')
