-- Checks plan.lua: lua test.lua
package.path = arg[0]:gsub("test%.lua$", "?.lua;") .. package.path
local plan = require("plan")

-- A listing's entries; tests move first and newline where vis's marks would go
local function listed(text)
  local entries = {}
  for start, name, nl in text:gmatch("()([^\n]*)()\n") do
    entries[#entries + 1] = { name = name, first = start - 1, newline = nl - 1 }
  end
  return entries
end

local function same(got, want)
  local a, b = {}, {}
  for _, op in ipairs(got) do
    a[#a + 1] = table.concat(op, " ")
  end
  for _, op in ipairs(want) do
    b[#b + 1] = table.concat(op, " ")
  end
  local x, y = table.concat(a, "|"), table.concat(b, "|")
  assert(x == y, x .. " ~= " .. y)
end

local original = "sub/\na.txt\nb.txt\n" -- offsets: sub/ 0-4, a.txt 5-10, b.txt 11-16
local e = listed(original)
same(plan(original, e), {})

-- cw on b.txt: its first byte is gone, its newline moved back one byte
e = listed(original)
e[3].first, e[3].newline = nil, 15
same(plan("sub/\na.txt\nc.md\n", e), { { "rename", "b.txt", "c.md" } })

-- A on a.txt, typing .bak: both stay
e = listed(original)
e[3].first, e[3].newline = 15, 20
same(plan("sub/\na.txt.bak\nb.txt\n", e), { { "rename", "a.txt", "a.txt.bak" } })

-- o on a.txt: the new line takes a.txt's newline, a.txt keeps its first byte
e = listed(original)
e[2].newline = 14
e[3].first, e[3].newline = 15, 20
same(plan("sub/\na.txt\nnew\nb.txt\n", e), { { "create", "new" } })

-- dd on a.txt: both bytes gone
e = listed(original)
e[2].first, e[2].newline = nil, nil
e[3].first, e[3].newline = 5, 10
same(plan("sub/\nb.txt\n", e), { { "delete", "a.txt" } })

-- dd then p elsewhere: the same name comes back, nothing happens
same(plan("sub/\nb.txt\na.txt\n", e), {})

-- new lines: a folder and a nested file; blank lines and spaces don't count
e = listed(original)
same(plan(original .. "\nnew/\n  x/y.lua  \n", e), { { "create", "new/" }, { "create", "x/y.lua" } })

-- a line cleared with 0D: the newline stays on an empty line, so it's a delete
e = listed(original)
e[2].first, e[2].newline = nil, 5
e[3].first, e[3].newline = 6, 11
same(plan("sub/\n\nb.txt\n", e), { { "delete", "a.txt" } })

-- errors
assert(not plan(original .. "..\n", listed(original)))
assert(not plan(original .. "n\nn\n", listed(original)))
print("ok")
