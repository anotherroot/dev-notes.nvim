local Dev = require("dev-notes.dev")
local log = Dev.log

local DevNotes = {}

---Configures the plugin
---@param config? DevNotesConfig User configuration
---@return DevNotesConfig #Returns the modified config
---@see dev-notes.config
---@usage [[
----- Use default configuration
---require('Comment').setup({})
---
----- or with custom configuration
---require('Comment').setup({
---   local_save = true
---})
---@usage ]]
function DevNotes.setup(config)
    log.trace("setup(): ", vim.inspect(config))

    config = require("dev-notes.config").set(config).get()

    if config.use_default_mappings then
        vim.keymap.set(
            "n",
            "<A-n>",
            ':lua require"dev-notes.ui".toggle_quick_note()<CR>'
        )
    end

    log.debug("setup() -> config:", vim.inspect(config))

    -- setup initial files





    return config
end

return DevNotes
