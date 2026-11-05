-- Rime Frost: frost-white paper under the same cold accents, rime's light variant.
-- themes/rime.lua, loaded under this name so it picks the frost palette
local dir = debug.getinfo(1, 'S').source:sub(2):match('(.*/)')
return assert(loadfile(dir .. 'rime.lua'))('themes/rime-frost')
