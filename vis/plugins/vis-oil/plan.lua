-- What an edited oil buffer asks for. No vis here, so test.lua runs it in plain lua.
--
-- text: the buffer. entries: { name, first, newline } as listed, with the
-- current offsets of the name's first character and its newline, nil once
-- deleted. An entry's line is its first character's, which survives o and
-- Enter, else its newline's, which survives retyping the name. Neither: deleted
--
-- Returns { "rename", from, to }, { "create", name } and { "delete", name }
-- ops, or nil and an error

local function trim(s)
  return s:match("^%s*(.-)%s*$")
end

local function bad(name)
  local plain = name:gsub("/+$", "")
  return plain == "" or plain == "." or plain == ".." or name:find("\0", 1, true)
end

return function(text, entries)
  if text ~= "" and text:sub(-1) ~= "\n" then
    text = text .. "\n"
  end
  local lines = {} -- { name, start, stop }: 0-based offsets of the first byte and newline
  for start, line, stop in text:gmatch("()([^\n]*)()\n") do
    lines[#lines + 1] = { name = trim(line), start = start - 1, stop = stop - 1 }
  end
  local function line_at(pos)
    local lo, hi = 1, #lines
    while pos and lo <= hi do
      local mid = math.floor((lo + hi) / 2)
      local l = lines[mid]
      if pos < l.start then
        hi = mid - 1
      elseif pos > l.stop then
        lo = mid + 1
      else
        return l
      end
    end
  end

  local ops, deleted = {}, {}
  for _, entry in ipairs(entries) do
    local l = line_at(entry.first) or line_at(entry.newline)
    if l and not l.claimed and l.name ~= "" then
      l.claimed = true
      if l.name ~= entry.name then
        ops[#ops + 1] = { "rename", entry.name, l.name }
      end
    else
      deleted[entry.name] = true
    end
  end

  -- Renames first, so a new entry can take a renamed one's old name. A line
  -- moved with dd and p comes back under its own name: nothing to do
  for _, l in ipairs(lines) do
    if not l.claimed and l.name ~= "" then
      if deleted[l.name] then
        deleted[l.name] = nil
      else
        ops[#ops + 1] = { "create", l.name }
      end
    end
  end
  local names = {}
  for name in pairs(deleted) do
    names[#names + 1] = name
  end
  table.sort(names)
  for _, name in ipairs(names) do
    ops[#ops + 1] = { "delete", name }
  end

  local targets = {}
  for _, op in ipairs(ops) do
    local target = op[1] == "rename" and op[3] or op[1] == "create" and op[2]
    if target then
      if bad(target) then
        return nil, "not a file name: " .. target
      end
      local key = target:gsub("/+$", "")
      if targets[key] then
        return nil, "two entries named " .. target
      end
      targets[key] = true
    end
  end
  return ops
end
