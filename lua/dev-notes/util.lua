local Util = {}

math.randomseed(os.time())

function Util.uuid()
    local template = "xxxxxxxxxx-"
    return string.gsub(template, "[x]", function(c)
        local v = (c == "x") and math.random(0, 0xf) or math.random(8, 0xb)
        return string.format("%x", v)
    end) .. os.time()
end

return Util
