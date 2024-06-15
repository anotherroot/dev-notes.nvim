local Path = require("plenary.path")

local log = require("dev-notes.dev").log
local Util = require("dev-notes.util")
local Config = require("dev-notes.config")

local Note = {}

local data_path = string.format("%s/%s", vim.fn.stdpath("data"), "dev-notes")
local notes_file = string.format("%s/dev-notes.json", data_path)

if not Path:new(data_path):exists() then
    Path:new(data_path):mkdir()
    vim.fn.writefile({ "{}" }, notes_file)
    local _ = vim.api.nvim_exec2(
        string.format("!git init %s", data_path),
        { output = true }
    )
end

local project_notes = {}
local loaded = false

local function read_file(file)
    local file_path = string.format("%s/%s", data_path, file)
    local lines = vim.fn.readfile(file_path)
    return lines
end

local function write_file(file, lines)
    local file_path = string.format("%s/%s", data_path, file)
    vim.fn.writefile(lines, file_path)
end

function Note.get_notes()
    log.trace("note.get_notes()")

    if loaded == false then
        loaded = true
        local path = Path:new(notes_file)
        if not path:exists() then
            path:write("{}")
        end
        project_notes = vim.json.decode(path:read())
    end
    return project_notes
end

function Note.get(pwd)
    log.trace("note.get()")

    local notes = Note.get_notes()

    if notes[pwd] then
        return { lines = read_file(notes[pwd].file), cursor = notes[pwd].cursor }
    else
        return { lines = {}, cursor = { 0, 0 } }
    end
end

local function git_commit()
    if Config.get().use_git_for_versioning then
        local _ = vim.api.nvim_exec2(
            string.format("!git -C %s add .", data_path),
            { output = true }
        )
        local _ = vim.api.nvim_exec2(
            string.format("!git -C %s commit -m 'automated commit'", data_path),
            { output = true }
        )
    end
end

function Note.set(pwd, lines, cursor)
    log.trace("note.set()")

    local file_name = Util.uuid()
    if project_notes[pwd] then
        file_name = project_notes[pwd].file
    end
    write_file(file_name, lines)

    project_notes[pwd] = { file = file_name, cursor = cursor }

    Path:new(notes_file):write(vim.fn.json_encode(project_notes), "w")

    git_commit()
end

return Note
