---Plugin's configuration
---@class DevNotesConfig
---Controls space between the comment
---and the line (default: 'false')
---@field local_save boolean|fun():boolean
---@field quick_notes QuickNotesConfig
---@field use_default_mappings boolean
---
---Create default mappings
---@class QuickNotesConfig
---@field width integer
---@field height integer
---@field border_chars string[]
---@field save_on_edit boolean
---@field save_on_exit boolean

local log = require("dev-notes.dev").log

---@private
---@class RootConfig
---@field config DevNotesConfig
local Config = {
    config = {
        local_save = false,
        use_default_mappings = true,
        quick_notes = {
            width = 80,
            height = 15,
            border_chars = {
                "─",
                "│",
                "─",
                "│",
                "╭",
                "╮",
                "╯",
                "╰",
            },
            save_on_edit = true,
            save_on_exit = true,
        },
    },
}

---@package
---Updates the default config
---@param config? DevNotesConfig
---@return RootConfig
---@see comment.usage.setup
---@usage `require('Comment.config').set({config})`
function Config.set(config)
    log.trace("config.set(config):", config)

    if config then
        Config.config = vim.tbl_deep_extend("force", Config.config, config)
    end
    return Config
end

---Get the config
---@return DevNotesConfig
---@usage `require('Comment.config').get()`
function Config.get()
    log.trace("config.get()")
    return Config.config
end

return Config
