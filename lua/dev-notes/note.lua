local Path = require("plenary.path")

local log = require("dev-notes.dev").log

local Note = {}

local data_path = vim.fn.stdpath("data")
local notes_file = string.format("%s/dev-notes.json", data_path)

local project_notes = nil

function Note.get_notes()
    log.trace("note.get_notes()")

    if project_notes == nil then
        project_notes = vim.json.decode(Path:new(notes_file):read())
    end
    return project_notes
end

function Note.get(pwd)
    log.trace("note.get()")

    local notes = Note.get_notes()
    if notes[pwd] then
        return notes[pwd]
    else
        return { lines = {}, cursor = { 0, 0 } }
    end
end

function Note.set(pwd, lines, cursor)
    log.trace("note.set()")

    project_notes[pwd] = { lines = lines, cursor = cursor }

    Path:new(notes_file):write(vim.fn.json_encode(project_notes), "w")
end

return Note
