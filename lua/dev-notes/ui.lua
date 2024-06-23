local popup = require("plenary.popup")
local pickers = require("telescope.pickers")
local finders = require("telescope.finders")
local conf = require("telescope.config").values
local actions = require("telescope.actions")
local action_state = require("telescope.actions.state")

local log = require("dev-notes.dev").log
local Config = require("dev-notes.config")
local Note = require("dev-notes.note")
local Util = require("dev-notes.util")

local UI = {}

local win_id = nil
local buf_id = nil

local current_note_directory = nil
local current_note_name = nil

local function create_window(title)
    log.trace("create_window()")

    local config = Config.get().quick_notes
    local width = config.width or 60
    local height = config.height or 10
    local borderchars = config.border_chars
        or { "─", "│", "─", "│", "╭", "╮", "╯", "╰" }

    local bufnr = vim.api.nvim_create_buf(false, false)

    local new_win_id, win = popup.create(bufnr, {
        title = title,
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

function UI.close_note(opts)
    opts = opts or {}
    log.trace("ui.close_menu(opts): ", vim.inspect(opts))
    if Config.get().quick_notes.save_on_exit or opts.force_save then
        UI.save_open_note()
    end
    if win_id == nil then
        return
    end

    vim.api.nvim_win_close(win_id, true)

    win_id = nil
    buf_id = nil
    current_note_directory = nil
    current_note_name = nil
end

function UI.toggle_quick_note()
    log.trace("ui.toggle_quick_note()")
    if win_id ~= nil and vim.api.nvim_win_is_valid(win_id) then
        UI.close_note()
        return
    end

    UI.open_note()

    log.trace("toggle_quick_note(): End")
end

function UI.save_open_note()
    log.trace("ui.save_open_note()")
    assert(win_id ~= nil, "win_id must not be nil")
    Note.set(
        current_note_directory,
        current_note_name,
        get_quick_note_lines(),
        vim.api.nvim_win_get_cursor(win_id)
    )
end

function UI.open_note(opts)
    log.trace("ui.open_note(opts):", vim.inspect(opts))
    opts = opts or {}
    local config = Config.get()

    if opts.name == nil then
        opts.name = "Quick notes"
    end
    if opts.pwd == nil then
        opts.pwd = vim.loop.cwd()
    end

    local window_title = opts.name

    if opts.pwd ~= vim.loop.cwd() then
        window_title = string.format(
            "%s - %s",
            Util.gsub(opts.pwd, config.home_dir, "~"),
            opts.name
        )
    end

    local win_info = create_window(window_title)

    win_id = win_info.win_id
    buf_id = win_info.bufnr
    current_note_directory = opts.pwd
    current_note_name = opts.name

    local note_data = Note.get(opts.pwd, opts.name)
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
            "autocmd BufWriteCmd <buffer=%s> lua require('dev-notes.ui').save_open_note()",
            buf_id
        )
    )
    if Config.get().quick_notes.save_on_edit then
        vim.cmd(
            string.format(
                "autocmd TextChanged,TextChangedI <buffer=%s> lua require('dev-notes.ui').save_open_note()",
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
        "autocmd BufLeave <buffer> ++nested ++once silent lua require('dev-notes.ui').save_open_note()"
    )
end

function UI.open_note_picker(opts)
    log.trace("ui.open_note_picker(opts):", vim.inspect(opts))
    opts = opts or {}
    local config = Config.get()

    if opts.from_all_projects == nil then
        opts.from_all_projects = false
    end

    if opts.only_quick_notes == nil then
        opts.only_quick_notes = false
    end

    local project_notes = Note.get_notes()

    local notes = {}

    if opts.from_all_projects then
        for path, project in pairs(project_notes) do
            local files = project.files
            if files ~= nil then
                for name, note in pairs(files) do
                    table.insert(
                        notes,
                        { path = path, file = note.file, name = name }
                    )
                end
            end
        end
    else
        local path = vim.loop.cwd()
        local project = project_notes[path]
        local files = project.files
        if files ~= nil then
            for name, note in pairs(files) do
                table.insert(
                    notes,
                    { path = path, file = note.file, name = name }
                )
            end
        end
    end

    local notes_directory = Note.get_notes_directory()

    pickers
        .new(opts, {
            prompt_title = "Pick a note from all projects",
            finder = finders.new_table({
                results = notes,
                entry_maker = function(note)
                    local display = string.format(
                        "%s - %s",
                        Util.gsub(note.path, config.home_dir, "~"),
                        note.name
                    )
                    return {
                        value = note,
                        display = display,
                        ordinal = display,
                        path = string.format(
                            "%s/%s",
                            notes_directory,
                            note.file
                        ),
                    }
                end,
            }),
            previewer = conf.grep_previewer(opts),
            sorter = conf.generic_sorter(opts),
            attach_mappings = function(prompt_bufnr, map)
                actions.select_default:replace(function()
                    actions.close(prompt_bufnr)
                    local selection = action_state.get_selected_entry()
                    local line = action_state.get_current_line()

                    if selection ~= nil then
                        UI.open_note({
                            pwd = selection.value.path,
                            name = selection.value.name,
                        })
                    elseif line:gsub("%s+", "") ~= "" then
                        UI.open_note({ name = line })
                    end
                end)
                return true
            end,
        })
        :find()
end

return UI
