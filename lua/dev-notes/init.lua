local Dev = require("dev-notes.dev")
local Config = require("dev-notes.config")
local log = Dev.log

local DevNotes = {}

local dev_notes_root =
    vim.api.nvim_create_augroup("DEV_NOTES_ROOT", { clear = true })

vim.api.nvim_create_autocmd("FileType", {
    pattern = "devnotes",
    group = dev_notes_root,
    callback = function()
        log.trace("FileType devnotes(): in init.lua")

        if not Config.get().use_default_augroup_mappings then
            return
        end

        vim.keymap.set(
            "n",
            "<esc>",
            ':lua require"dev-notes.ui".toggle_quick_note()<CR>'
        )
    end,
})

---Configures the plugin
---@param config? DevNotesConfig User configuration
---@return DevNotesConfig #Returns the modified config
---@see dev-notes.config
---@usage [[
----- Use default configuration
---require('dev-notes').setup({})
---
----- or with custom configuration
---require('dev-notes').setup({
---   use_git_for_versioning = false,
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
        vim.keymap.set(
            "n",
            "<A-S-n>",
            ':lua require"dev-notes.ui".toggle_quick_note_test()<CR>'
        )
    end

    log.debug("setup() -> config:", vim.inspect(config))

    return config
end

return DevNotes
