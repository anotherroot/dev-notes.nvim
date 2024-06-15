local popup = require("plenary.popup")

local log = require("dev-notes.dev").log
local Config = require("dev-notes.config")
local Note = require("dev-notes.note")

local UI = {}

local win_id = nil
local buf_id = nil

local function close_menu(force_save)
    log.trace("close_menu(force_save): ", vim.inspect(force_save))
    if Config.get().quick_notes.save_on_exit or force_save then
        UI.on_quick_notes_save()
    end
    if win_id == nil then
        return
    end

    vim.api.nvim_win_close(win_id, true)

    win_id = nil
    buf_id = nil
end

local function create_window()
    log.trace("create_window()")
    local config = Config.get().quick_notes
    local width = config.width or 60
    local height = config.height or 10
    local borderchars = config.border_chars
        or { "─", "│", "─", "│", "╭", "╮", "╯", "╰" }

    local bufnr = vim.api.nvim_create_buf(false, false)

    local new_win_id, win = popup.create(bufnr, {
        title = "Quick Notes",
        highlight = "DevNotesWindow",
        line = math.floor(((vim.o.lines - height) / 2) - 1),
        col = math.floor((vim.o.columns - width) / 2),
        minwidth = width,
        minheight = height,
        borderchars = borderchars,
    })

    vim.api.nvim_set_option_value(
        "winhl",
        "Normal:DevNotesBorder",
        { win = win.border.win_id }
    )

    return {
        bufnr = bufnr,
        win_id = new_win_id,
    }
end

local function get_quick_note_lines()
    log.trace("get_quick_note_lines()")

    assert(buf_id ~= nil, "buf_id must not be nil")

    local lines = vim.api.nvim_buf_get_lines(buf_id, 0, -1, true)
    return lines
end

---Toggle quick note
---@return nil #Returns nil
function UI.toggle_quick_note()
    log.trace("ui.toggle_quick_note()")
    if win_id ~= nil and vim.api.nvim_win_is_valid(win_id) then
        close_menu()
        return
    end

    local win_info = create_window()

    win_id = win_info.win_id
    buf_id = win_info.bufnr

    local note_data = Note.get(vim.loop.cwd())
    local contents = note_data.lines

    local cursor = note_data.cursor

    vim.api.nvim_set_option_value("number", true, { win = win_id })
    vim.api.nvim_buf_set_name(buf_id, "dev-notes-menu")
    vim.api.nvim_buf_set_lines(buf_id, 0, #contents, false, contents)
    vim.api.nvim_set_option_value("filetype", "devnotes", { buf = buf_id })
    vim.api.nvim_set_option_value("buftype", "acwrite", { buf = buf_id })
    vim.api.nvim_set_option_value("bufhidden", "delete", { buf = buf_id })

    if cursor[1] ~= 0 then
        vim.api.nvim_win_set_cursor(win_id, cursor)
    end

    vim.cmd(
        string.format(
            "autocmd BufWriteCmd <buffer=%s> lua require('dev-notes.ui').on_quick_notes_save()",
            buf_id
        )
    )
    if Config.get().quick_notes.save_on_edit then
        vim.cmd(
            string.format(
                "autocmd TextChanged,TextChangedI <buffer=%s> lua require('dev-notes.ui').on_quick_notes_save()",
                buf_id
            )
        )
    end
    vim.cmd(
        string.format(
            "autocmd BufModifiedSet <buffer=%s> set nomodified",
            buf_id
        )
    )
    vim.cmd(
        "autocmd BufLeave <buffer> ++nested ++once silent lua require('dev-notes.ui').toggle_quick_note()"
    )

    log.trace("toggle_quick_note(): End")
end

function UI.on_quick_notes_save()
    log.trace("ui.on_quick_notes_save()")
    assert(win_id ~= nil, "win_id must not be nil")

    local pwd = vim.loop.cwd()

    Note.set(pwd, get_quick_note_lines(), vim.api.nvim_win_get_cursor(win_id))
end

return UI
