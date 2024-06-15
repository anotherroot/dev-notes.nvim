---Plugin's configuration
---@class DevNotesConfig
---Controls whether to use default
---mappings (default: true)
---@field use_default_mappings boolean
---Controls whether to use default
---augroup mappings (default: true)
---@field use_default_augroup_mappings boolean
---Controls default weather to use git
---for versioning of quick notes (default: true)
--- - useful to not loose important notes
---@field use_git_for_versioning boolean
---Controls the behavior of the quick notes
---popup (default: lots of stuf)
---@field quick_notes QuickNotesConfig

---@class QuickNotesConfig
---Controls the width of quick notes
---popup (default: 80)
---@field width integer
---Controls the height of quick notes
---popup (default: 15)
---@field height integer
---Controls the characters used for
---quick notes popup, using Plenary
---popup (default: { "─", "│", "─", "│", "╭", "╮", "╯", "╰" })
---@field border_chars string[]
---Controls whether the quick note
---saves on ever individual edit
---(default: false)
--- - probably not good to use with
---   "use_git_for_versioning"
---@field save_on_edit boolean
---Controls whether the quick note
---saved when you exit it
---(default: true)
---@field save_on_exit boolean

local log = require("dev-notes.dev").log

---@private
---@class RootConfig
---@field config DevNotesConfig
local Config = {
    config = {
        use_default_mappings = true,
        use_default_augroup_mappings = true,
        use_git_for_versioning = true,
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
            save_on_edit = false,
            save_on_exit = true,
        },
    },
}

---@package
---Updates the default config
---@param config? DevNotesConfig
---@return RootConfig
---@see comment.usage.setup
---@usage `require('dev-notes.config').set({config})`
function Config.set(config)
    log.trace("config.set(config):", config)

    if config then
        Config.config = vim.tbl_deep_extend("force", Config.config, config)
    end
    return Config
end

---Get the config
---@return DevNotesConfig
---@usage `require('dev-notes.config').get()`
function Config.get()
    log.trace("config.get()")
    return Config.config
end

return Config
