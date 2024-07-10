local M = {}

-- local log_levels = { "trace", "debug", "info", "warn", "error", "fatal" }

function M.reload()
  require("plenary.reload").reload_module("dev-notes")
end

local log = nil

function M.get_log()
  if log == nil then
    log = require("plenary.log").new({
      plugin = "dev-notes",
      level = "warn",
    })
  end
  return log
end

return M
