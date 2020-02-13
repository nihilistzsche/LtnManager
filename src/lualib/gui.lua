-- -------------------------------------------------------------------------------------------------------------------------------------------------------------
-- RAILUALIB GUI MODULE
-- GUI templating and event handling

-- Copyright (c) 2020 raiguard - https://github.com/raiguard
-- Permission is hereby granted, free of charge, to those obtaining this software or a portion thereof, to copy the contents of this software into their own
-- Factorio mod, and modify it to suit their needs. This is permissed under the condition that this notice and copyright information, as well as the link to
-- the documentation, are not omitted, and that any changes from the original are documented.

-- DOCUMENTATION: https://github.com/raiguard/Factorio-SmallMods/wiki/GUI-Module-Documentation

-- -------------------------------------------------------------------------------------------------------------------------------------------------------------

-- dependencies
local event = require('lualib/event')
local util = require('__core__/lualib/util')

-- locals
local global_data
local string_find = string.find
local string_gsub = string.gsub
local string_split = util.split
local table_deepcopy = table.deepcopy
local table_insert = table.insert
local table_merge = util.merge

-- settings
local handlers = {}
local templates = {}

-- objects
local self = {}

-- -----------------------------------------------------------------------------
-- LOCAL UTILITIES

local function get_subtable(s, t)
  local o = table_deepcopy(t)
  for _,key in pairs(string_split(s, '%.')) do
    o = o[key]
  end
  return o
end

local function register_handlers(gui_name, handlers_path, options)
  local handlers_t = get_subtable(gui_name..'.'..handlers_path, handlers)
  for n,func in pairs(handlers_t) do
    local t = table.deepcopy(options)
    t.name = 'gui.'..gui_name..'.'..handlers_path..'.'..n
    -- add to global table
    if not global_data[gui_name] then global_data[gui_name] = {} end
    if not global_data[gui_name][t.player_index] then global_data[gui_name][t.player_index] = {} end
    global_data[gui_name][t.player_index][t.name] = true
    if defines.events[n] then n = defines.events[n] end
    event.register(n, func, t)
  end
end

local function deregister_handlers(gui_name, handlers_path, player_index, gui_events)
  local handlers_t = get_subtable(gui_name..'.'..handlers_path, handlers)
  gui_events = gui_events or global_data[gui_name][player_index]
  if type(handlers_t) == 'function' then
    local name = 'gui.'..gui_name..'.'..handlers_path
    event.deregister_conditional(handlers_t, name, player_index)
    gui_events[name] = nil
  else
    for n,func in pairs(handlers_t) do
      event.deregister_conditional(func, n, player_index)
      gui_events[n] = nil
    end
  end
end

-- recursively load a GUI template
local function recursive_load(parent, t, output, name, player_index)
  -- load template(s)
  if t.template then
    local template = t.template
    if type(template) == 'string' then
      template = {template}
    end
    for i=1,#template do
      t = util.merge{get_subtable(template[i], templates), t}
    end
  end
  local elem
  -- skip all of this if it's a tab-and-content
  if t.type ~= 'tab-and-content' then
    -- format element table
    local elem_t = table_deepcopy(t)
    local style = elem_t.style
    local iterate_style = false
    if style and type(style) == 'table' then
      elem_t.style = style.name
      iterate_style = true
    end
    elem_t.children = nil
    -- create element
    elem = parent.add(elem_t)
    -- set runtime styles
    if iterate_style then
      for k,v in pairs(t.style) do
        if k ~= 'name' then
          elem.style[k] = v
        end
      end
    end
    -- apply modifications
    if t.mods then
      for k,v in pairs(t.mods) do
        elem[k] = v
      end
    end
    -- add to output table
    if t.save_as then
      if type(t.save_as) == 'boolean' then
        t.save_as = t.handlers
      end
      output[t.save_as] = elem
    end
    -- register handlers
    if t.handlers then
      register_handlers(name, t.handlers, {player_index=player_index, gui_filters=elem.index})
    end
    -- add children
    local children = t.children
    if children then
      for i=1,#children do
        output = recursive_load(elem, children[i], output, name, player_index)
      end
    end
  else
    local tab, content
    output, tab = recursive_load(parent, t.tab, output, name, player_index)
    output, content = recursive_load(parent, t.content, output, name, player_index)
    parent.add_tab(tab, content)
  end
  return output, elem
end

-- -----------------------------------------------------------------------------
-- SETUP

event.on_init(function()
  global.__lualib.gui = {}
  global_data = global.__lualib.gui
end)

event.on_load(function()
  global_data = global.__lualib.gui
  local con_registry = global.__lualib.event
  for n,t in pairs(con_registry) do
    if string_find(n, '^gui%.') then
      event.register(t.id, get_subtable(string_gsub(n, '^gui%.', ''), handlers), {name=n})
    end
  end
end)

-- -----------------------------------------------------------------------------
-- OBJECT

function self.create(parent, name, player_index, template)
  build_data = {}
  return recursive_load(parent, template, {}, name, player_index)
end

function self.destroy(parent, gui_name, player_index)
  -- deregister handlers
  local gui_tables = global_data[gui_name]
  if gui_tables then
    local list = gui_tables[player_index]
    for n,_ in pairs(list) do
      deregister_handlers(gui_name, string_gsub(n, '^gui%.'..gui_name..'%.', ''), player_index, list)
    end
    gui_tables[player_index] = nil
    if table_size(gui_tables) == 0 then
      global_data[gui_name] = nil
    end
  end
  -- destroy GUI
  parent.destroy()
end

function self.add_templates(...)
  local arg = {...}
  if #arg == 1 then
    for k,v in pairs(arg[1]) do
      templates[k] = v
    end
  else
    templates[arg[1]] = arg[2]
  end
  return self
end

function self.add_handlers(...)
  local arg = {...}
  if #arg == 1 then
    for k,v in pairs(arg[1]) do
      handlers[k] = v
    end
  else
    handlers[arg[1]] = arg[2]
  end
  return self
end

-- calls a GUI template as a function
function self.call_template(path, ...)
  return get_subtable(path, templates)(...)
end

-- retrieves and returns a GUI template
function self.get_template(path)
  return get_subtable(path, templates)
end

-- calls a GUI handler
function self.call_handler(path, ...)
  return get_subtable(path, handlers)(...)
end

-- retrieves and returns a handler
function self.get_handler(path)
  return get_subtable(path, handlers)
end

self.register_handlers = register_handlers
self.deregister_handlers = deregister_handlers

return self