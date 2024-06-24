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

function Note.get_notes_directory()
  return data_path
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

function Note.get(pwd, name)
  log.trace("note.get()")

  local notes = Note.get_notes()

  if notes[pwd] and notes[pwd].files and notes[pwd].files[name] then
    local file = notes[pwd].files[name].file
    local cursor = notes[pwd].files[name].cursor
    return { lines = read_file(file), cursor = cursor }
  else
    return { lines = {}, cursor = { 0, 0 } }
  end
end

function Note.get_last_note_name(pwd)
  log.trace("note.get_last_note_name(pwd):", vim.inspect(pwd))

  local notes = Note.get_notes()

  if
    notes[pwd]
    and notes[pwd].files
    and notes[pwd].last_note
    and notes[pwd].last_note.name
  then
    return notes[pwd].last_note.name
  else
    return nil
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

function Note.rename(pwd, old_name, new_name)
  log.trace(
    "note.rename(pwd,old_name,new_name):",
    vim.inspect(pwd),
    vim.inspect(old_name),
    vim.inspect(new_name)
  )
  local project = Note.get_notes()[pwd]

  assert(project ~= nil, string.format("project at %s doesn'e exist!", pwd))

  local old_note = project.files[old_name]

  assert(
    old_note ~= nil,
    string.format("Note named %s doesn't exist!", old_note)
  )

  if project.files[new_name] ~= nil then
    log.debug(string.format("Note with name '%s' already exists!", new_name))
    return nil
  end

  project.files[new_name] = old_note
  project.files[old_name] = nil

  if
    project.last_note
    and project.last_note.name
    and project.last_note.name == old_name
  then
    project_notes.last_note.name = new_name
  end

  project_notes[pwd] = project

  Path:new(notes_file):write(vim.fn.json_encode(project_notes), "w")

  git_commit()

  return new_name
end

function Note.set(pwd, name, lines, cursor)
  log.trace("note.set(pwd, name, lines, cursor):", pwd, name, lines, cursor)

  local config = Config.get()

  local project = nil
  if project_notes[pwd] then
    project = project_notes[pwd]
  end
  project = project or { files = {}, last_note = { name = nil } }

  local file_name = Util.uuid()
  if project.files[name] then
    file_name = project.files[name].file
  end

  write_file(file_name, lines)

  project.files[name] = {
    file = file_name,
    cursor = cursor,
  }
  if
    name ~= config.quick_notes_name or config.quick_notes_can_also_be_last_note
  then
    project.last_note.name = name
  end

  project_notes[pwd] = project

  Path:new(notes_file):write(vim.fn.json_encode(project_notes), "w")

  git_commit()
end

return Note
