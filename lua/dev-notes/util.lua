local Util = {}

math.randomseed(os.time())

function Util.uuid()
  local template = "xxxxxxxxxx-"
  return string.gsub(template, "[x]", function(c)
    local v = (c == "x") and math.random(0, 0xf) or math.random(8, 0xb)
    return string.format("%x", v)
  end) .. os.time()
end

function Util.get_keys(t)
  local keys = {}
  for key, _ in pairs(t) do
    table.insert(keys, key)
  end
  return keys
end

function Util.gsub(str, pat, val)
  if pat == nil then
    return str
  end
  return str:gsub(pat, val)
end

return Util
