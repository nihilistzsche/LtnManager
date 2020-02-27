-- -------------------------------------------------------------------------------------------------------------------------------------------------------------
-- RAILUALIB EVENT MODULE
-- Multi-handler registration, conditional event handling, and GUI event filtering.

-- Copyright (c) 2020 raiguard - https://github.com/raiguard
-- Permission is hereby granted, free of charge, to those obtaining this software or a portion thereof, to copy the contents of this software into their own
-- Factorio mod, and modify it to suit their needs. This is permissed under the condition that this notice and copyright information, as well as the link to
-- the documentation, are not omitted, and that any changes from the original are documented.

-- DOCUMENTATION: https://github.com/raiguard/Factorio-SmallMods/wiki/Event-Module-Documentation

-- -------------------------------------------------------------------------------------------------------------------------------------------------------------

local util = require('__core__/lualib/util')

-- locals
local table_deepcopy = table.deepcopy
local table_insert = table.insert

-- module
local event = {}
-- holds registered events
local event_registry = {}

-- GUI filter matching functions
local gui_filter_matchers = {
  string = function(element, filter) return element.name:match(filter) end,
  number = function(element, filter) return element.index == filter end,
  table = function(element, filter) return element == filter end
}

-- calls handler functions tied to an event
-- ALL events go through this function
local function dispatch_event(e)
  local global_data = global.__lualib.event
  local id = e.name
  -- set ID for special events
  if e.nth_tick then
    id = -e.nth_tick
  end
  if e.input_name then
    id = e.input_name
  end
  -- error checking
  if not event_registry[id] then
    error('Event is registered but has no handlers!')
  end
  for _,t in ipairs(event_registry[id]) do -- for every handler registered to this event
    local options = t.options
    if not options.skip_validation then
      -- check if any userdata has gone invalid since last iteration
      for _,v in pairs(e) do
        if type(v) == 'table' and v.__self and not v.valid then
          return event
        end
      end
    end
    -- if we are a conditional event, insert registered players
    local name = options.name
    local gui_filters
    if name then
      local con_data = global_data[name]
      if not con_data then error('Conditional event has been raised, but has no data!') end
      e.registered_players = con_data.players
      -- if there are GUI filters, check them
      gui_filters = con_data.gui_filters[e.player_index]
      if not gui_filters and table_size(con_data.gui_filters) > 0 then
        goto continue
      end
    else
      gui_filters = t.gui_filters
    end
    -- check GUI filters, if any
    if gui_filters then
      -- check GUI filters if they exist
      local elem = e.element
      if not elem then
        -- there is no element to filter, so skip calling the handler
        log('Event '..id..' has GUI filters but no GUI element, skipping!')
        goto continue
      end
      local matchers = gui_filter_matchers
      for i=1,#gui_filters do
        local filter = gui_filters[i]
        if matchers[type(filter)](elem, filter) then
          goto call_handler
        end
      end
      -- if we're here, none of the filters matched, so don't call the handler
      goto continue
    end
    ::call_handler::
    -- call the handler
    t.handler(e)
    ::continue::
    if options.force_crc then
      game.force_crc()
    end
  end
  return event
end
-- pass-through handlers for special events
local bootstrap_handlers = {
  on_init = function()
    dispatch_event{name='on_init'}
  end,
  on_load = function()
    dispatch_event{name='on_load'}
  end,
  on_configuration_changed = function(e)
    e.name = 'on_configuration_changed'
    dispatch_event(e)
  end
}

-- -----------------------------------------------------------------------------
-- EVENTS

-- registers a handler to run when the event is called
function event.register(id, handler, options)
  options = options or {}
  -- we must do this here as well since this can get called before on_init
  if not global.__lualib then global.__lualib = {event={}} end
  -- locals
  local global_data = global.__lualib.event
  local name = options.name
  local player_index = options.player_index
  local gui_filters = options.gui_filters
  -- nest GUI filters into an array if they're not already
  if gui_filters then
    if type(gui_filters) ~= 'table' or gui_filters.gui then
      gui_filters = {gui_filters}
    end
  end
  -- add to conditional event registry
  if name then
    local t = global_data[name]
    local skip_registration = false
    if not t then
      global_data[name] = {id=id, players={}, gui_filters={}}
      t = global_data[name]
    elseif player_index then
      -- check if the player already registered this event
      local players = t.players
      for i=1,#players do
        if players[i] == player_index then
          -- don't do anything
          if not options.suppress_logging then
            log('Tried to re-register conditional event \''..name..'\' for player '..player_index..', skipping!')
          end
          return event
        end
      end
      -- if we're here, we want to do everything for the conditional event but not register the handler
      skip_registration = true
    end
    if gui_filters then
      if player_index then
        t.gui_filters[player_index] = gui_filters
      else
        error('Must specify a player_index when using gui filters on a conditional event.')
      end
    end
    if player_index then
      table_insert(t.players, player_index)
    end
    if skip_registration then return event end
  end
  -- register handler
  if type(id) ~= 'table' then id = {id} end
  for _,n in pairs(id) do
    -- create event registry if it doesn't exist
    if not event_registry[n] then
      event_registry[n] = {}
    end
    local registry = event_registry[n]
    -- create master handler if not already created
    if #registry == 0 then
      if type(n) == 'number' and n < 0 then
        script.on_nth_tick(-n, dispatch_event)
      elseif type(n) == 'string' and bootstrap_handlers[n] then
        script[n](bootstrap_handlers[n])
      else
        script.on_event(n, dispatch_event)
      end
    end
    -- make sure the handler has not already been registered
    for i,t in ipairs(registry) do
      -- if it is a conditional event,
      if t.handler == handler and not name then
        -- remove handler for re-insertion at the bottom
        if not options.suppress_logging then
          log('Re-registering existing event \''..n..'\', moving to bottom')
        end
        table.remove(registry, i)
      end
    end
    -- clean up options table, deepcopy it so the original is unmodified
    local n_options = table_deepcopy(options)
    n_options.player_index = nil
    n_options.gui_filters = nil
    if name then gui_filters = nil end
    -- add the handler to the events table
    local data = {handler=handler, gui_filters=gui_filters, options=n_options}
    if options.insert_at_front then
      table_insert(registry, 1, data)
    else
      table_insert(registry, data)
    end
  end
  return event -- function call chaining
end

-- deregisters a handler from the given event
function event.deregister(id, handler, name, player_index)
  local global_data = global.__lualib.event
  -- remove from conditional event registry if needed
  if name then
    local con_registry = global_data[name]
    if con_registry then
      if player_index then
        for i,pi in ipairs(con_registry.players) do
          if pi == player_index then
            table.remove(con_registry.players, i)
            break
          end
        end
        con_registry.gui_filters[player_index] = nil
      end
      if #con_registry.players == 0 then
        global_data[name] = nil
      else
        -- don't do anything else
        return event
      end
    else
      error('Tried to deregister a conditional event whose data does not exist')
    end
  end
  -- deregister handler
  if type(id) ~= 'table' then id = {id} end
  for _,n in pairs(id) do
    local registry = event_registry[n]
    -- error checking
    if not registry or #registry == 0 then
      log('Tried to deregister an unregistered event of id: '..n)
      return event
    end
    -- remove the handler from the events tables
    for i,t in ipairs(registry) do
      if t.handler == handler then
        table.remove(registry, i)
      end
    end
    -- de-register the master handler if it's no longer needed
    if table_size(registry) == 0 then
      if type(n) == 'number' and n < 0 then
        script.on_nth_tick(math.abs(n), nil)
      elseif type(n) == 'string' and bootstrap_handlers[n] then
        script[n](nil)
      else
        script.on_event(n, nil)
      end
    end
  end
  return event
end

-- raises an event as if it were actually called
function event.raise(id, table)
  script.raise_event(id, table)
  return event
end

-- set or remove event filters
function event.set_filters(id, filters)
  if type(id) ~= 'table' then id = {id} end
  for _,n in pairs(id) do
    script.set_event_filter(n, filters)
  end
  return event
end

-- holds custom event IDs
local custom_id_registry = {}
-- generates or retrieves a custom event ID
function event.generate_id(name)
  if not custom_id_registry[name] then
    custom_id_registry[name] = script.generate_event_name()
  end
  return custom_id_registry[name]
end

-- updates the GUI filters for the given conditional event
function event.update_gui_filters(name, player_index, filters)
  local event_data = global.__lualib.event[name]
  if not event_data then error('Cannot update GUI filters for a non-existent event!') end
  event_data.gui_filters[player_index] = filters
end

-- -------------------------------------
-- SHORTCUT FUNCTIONS

-- bootstrap events
function event.on_init(handler, options)
  return event.register('on_init', handler, options)
end

function event.on_load(handler, options)
  return event.register('on_load', handler, options)
end

function event.on_configuration_changed(handler, options)
  return event.register('on_configuration_changed', handler, options)
end

function event.on_nth_tick(nthTick, handler, options)
  return event.register(-nthTick, handler, options)
end

-- defines.events
for n,id in pairs(defines.events) do
  event[n] = function(handler, options)
    event.register(id, handler, options)
  end
end

-- -----------------------------------------------------------------------------
-- CONDITIONAL EVENTS

-- re-registers conditional handlers if they're in the registry
function event.load_conditional_handlers(data)
  local global_data = global.__lualib.event
  for name, handler in pairs(data) do
    local registry = global_data[name]
    if registry then
      event.register(registry.id, handler, {name=name})
    end
  end
  return event
end

-- returns true if the conditional event is registered
function event.is_registered(name, player_index)
  local registry = global.__lualib.event[name]
  if registry then
    if player_index then
      for _,i in ipairs(registry.players) do
        if i == player_index then
          return true
        end
      end
      return false
    end
    return true
  end
  return false
end

-- gets the event IDs from the conditional registry so you don't have to provide them
function event.deregister_conditional(handler, name, player_index)
  local con_registry = global.__lualib.event[name]
  if con_registry then
    event.deregister(con_registry.id, handler, name, player_index)
  end
end

function event.get_registry() return event_registry end

return event