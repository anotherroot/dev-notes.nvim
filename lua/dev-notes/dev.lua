local M = {}

-- local log_levels = { "trace", "debug", "info", "warn", "error", "fatal" }

function M.reload()
    require("plenary.reload").reload_module("dev-notes")
end

M.log = require("plenary.log").new({
    plugin = "dev-notes",
    level = "info",
})

return M
