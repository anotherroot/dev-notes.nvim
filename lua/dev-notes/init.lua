local Dev = require("dev-notes.dev")
local UI = require("dev-notes.ui")
local Config = require("dev-notes.config")
local log = Dev.log

local DevNotes = {}

local dev_notes_group =
  vim.api.nvim_create_augroup("DEV_NOTES_ROOT", { clear = true })

vim.api.nvim_create_autocmd("FileType", {
  pattern = "devnotes",
  group = dev_notes_group,
  callback = function()
    log.trace("FileType devnotes(): in init.lua")

    if not Config.get().use_default_augroup_mappings then
      return
    end

    vim.keymap.set("n", "<esc>", function()
      UI.toggle_quick_note()
    end, {
      buffer = true,
      noremap = true,
      silent = true,
      desc = "Exit dev-notes note",
    })
    vim.keymap.set({ "i", "n" }, "<C-c>", function()
      UI.toggle_quick_note()
    end, {
      buffer = true,
      noremap = true,
      silent = true,
      desc = "Exit dev-notes note",
    })
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
    vim.keymap.set("n", "<A-n>", function()
      UI.toggle_quick_note()
    end, { desc = "Toggle quick note of current proejct" })
    vim.keymap.set("n", "<A-S-n>", function()
      UI.toggle_quick_note({ open_last = true })
    end, { desc = "Open quick note in vsplit window" })
    vim.keymap.set("n", "<leader>pn", function()
      UI.open_note_picker()
    end, { desc = "Open note picker for current project" })
    vim.keymap.set("n", "<leader>apn", function()
      UI.open_note_picker({ from_all_projects = true })
    end, { desc = "Open note picker for all project notes" })
  end

  log.debug("setup() -> config:", vim.inspect(config))

  return config
end

return DevNotes
