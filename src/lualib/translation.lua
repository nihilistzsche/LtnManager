-- -------------------------------------------------------------------------------------------------------------------------------------------------------------
-- RAILUALIB TRANSLATION MODULE
-- Requests and organizes translations for localised strings

-- Copyright (c) 2020 raiguard - https://github.com/raiguard
-- Permission is hereby granted, free of charge, to those obtaining this software or a portion thereof, to copy the contents of this software into their own
-- Factorio mod, and modify it to suit their needs. This is permissed under the condition that this notice and copyright information, as well as the link to
-- the documentation, are not omitted, and that any changes from the original are documented.

-- DOCUMENTATION: https://github.com/raiguard/Factorio-SmallMods/wiki/Translation-Module-Documentation

-- -------------------------------------------------------------------------------------------------------------------------------------------------------------

-- dependencies
local event = require('lualib/event')
local util = require('__core__/lualib/util')

-- locals
local math_floor = math.floor
local string_gsub = string.gsub
local string_lower = string.lower
local table_sort = table.sort

-- -----------------------------------------------------------------------------

local translation = {}
translation.start_event = event.generate_id('translation_start')
translation.finish_event = event.generate_id('translation_finish')
translation.canceled_event = event.generate_id('translation_canceled')

-- converts a localised string into a format readable by the API
-- basically just spits out the table in string form
local function serialise_localised_string(t)
  local output = '{'
  if type(t) == 'string' then return t end
  for _,v in pairs(t) do
    if type(v) == 'table' then
      output = output..serialise_localised_string(v)
    else
      output = output..'\''..v..'\', '
    end
  end
  output = string_gsub(output, ', $', '')..'}'
  return output
end

-- translate 50 entries per tick
local function translate_batch(e)
  local __translation = global.__lualib.translation
  local iterations = math_floor(50 / __translation.active_translations_count)
  if iterations < 1 then iterations = 1 end
  local players = __translation.players
  -- for each player that is doing a translation
  for _,pi in ipairs(e.registered_players) do
    local pt = players[pi]
    local request_translation = game.get_player(pi).request_translation
    local next_index = pt.next_index
    local finish_index = next_index + iterations
    local strings = pt.strings
    local strings_len = pt.strings_len
    -- request translations for the next n strings
    for i=next_index,finish_index do
      if i > strings_len then
        -- deregister this event for this player
        event.deregister(defines.events.on_tick, translate_batch, 'translation_translate_batch', pi)
        goto continue
      end
      request_translation(strings[i])
    end
    -- update next index
    pt.next_index = finish_index + 1
    ::continue::
  end
end

-- sorts a translated string into its appropriate dictionaries
local function sort_translated_string(e)
  local __translation = global.__lualib.translation
  local player_data = __translation.players[e.player_index]
  local active_translations = player_data.active_translations
  local localised = e.localised_string
  local serialised = serialise_localised_string(localised)
  -- check if the string actually exists in the registry. if it does not, then another mod requested this translation as well and it was already sorted.
  local string_registry = player_data.string_registry[serialised]
  if string_registry then
    -- for each dictionary that requested this string
    for dictionary_name, internal_names in pairs(string_registry) do
      local data = active_translations[dictionary_name]
      -- extra sanity check
      if data then
        -- remove from registry index
        data.registry_index[serialised] = nil
        data.registry_index_size = data.registry_index_size - 1

        -- check if the string was successfully translated
        local success = e.translated
        local result = e.result
        local include_failed_translations = data.include_failed_translations
        if not include_failed_translations and (not success or result == '') then
          log(dictionary_name..':  key \''..serialised..'\' was not successfully translated, and will not be included in the output.')
        else
          -- do this only if the result will be the same for all internal names
          if success then
            -- convert to lowercase first if wanted
            if data.convert_to_lowercase then
              result = string_lower(result)
            end
            -- add to lookup table
            data.lookup[result] = internal_names
            -- add to sorted results table
            data.sorted_results[#data.sorted_results+1] = result
          end

          -- for every internal name that this string applies do
          for i=1,#internal_names do
            local internal = internal_names[i]
            -- set result to internal name if the translation failed and the option is active
            if not success and include_failed_translations then
              result = internal
              -- add to lookup and sorted_results tables here, as each iteration will have a different name
              local lookup = data.lookup[result]
              if lookup then
                lookup[#lookup+1] = internal
              else
                data.lookup[result] = {internal}
              end
              data.sorted_results[#data.sorted_results+1] = result
            -- convert to lowercase if the option is active and the translation succeeded
            elseif data.convert_to_lowercase then
              result = string_lower(result)
            end
            -- add to translations table
            if data.translations[internal] then
              error('Duplicate key \''..internal..'\' in dictionary: '..dictionary_name)
            else
              data.translations[internal] = result
            end
          end
        end

        -- check if this dictionary has finished translation
        if data.registry_index_size == 0 then
          -- sort sorted results table
          table_sort(data.sorted_results)
          -- decrement active translation counters
          __translation.active_translations_count = __translation.active_translations_count - 1
          player_data.active_translations_count = player_data.active_translations_count - 1
          -- raise finished event with the output tables
          event.raise(translation.finish_event, {player_index=e.player_index, dictionary_name=dictionary_name, lookup=data.lookup,
            sorted_results=data.sorted_results, translations=data.translations})
          -- remove from active translations table
          player_data.active_translations[dictionary_name] = nil

          -- check if the player is done translating
          if player_data.active_translations_count == 0 then
            -- deregister this event for this player
            event.deregister(defines.events.on_string_translated, sort_translated_string, 'translation_sort_result', e.player_index)
            -- reset for the next time stuff is translated
            player_data.next_index = 0
            player_data.strings = {}
            player_data.strings_len = 0
          end
        end
      else
        error('Data for dictionary: '..dictionary_name..' for player: '..e.player_index..' does not exist!')
      end
    end

    -- remove from string registry
    player_data.string_registry[serialised] = nil
  end
end

translation.serialise_localised_string = serialise_localised_string

-- begin translating strings
function translation.start(player, dictionary_name, data, options)
  options = options or {}
  local __translation = global.__lualib.translation
  local player_data = __translation.players[player.index]

  -- reset if the translation is already running
  if player_data.active_translations[dictionary_name] then
    log('Cancelling and restarting translation of '..dictionary_name..' for '..player.name)
    translation.cancel(player, dictionary_name)
  end

  -- create local references
  local string_registry = player_data.string_registry
  local strings = player_data.strings

  local registry_index = {} -- contains a table of keys that represent all the places in the string index that this dictionary has a place in

  -- add data to translation tables
  for i=1,#data do
    local t = data[i]
    local localised = t.localised
    local serialised = serialise_localised_string(localised)
    -- check for this string in the global string registry
    local registry_entry = string_registry[serialised]
    if registry_entry then
      -- check if this dictionary has been added to this registry yet
      if registry_index[serialised] then
        local our_registry = registry_entry[dictionary_name]
        our_registry[#our_registry+1] = t.internal
      else
        registry_index[serialised] = true
        registry_entry[dictionary_name] = {t.internal}
      end
    else
      -- this is a new string, so add it to the strings table and create the registry
      strings[#strings+1] = localised
      string_registry[serialised] = {[dictionary_name]={t.internal}}
      registry_index[serialised] = true
    end
  end

  -- set new strings table length
  player_data.strings_len = #strings

  -- add this dictionary's data to the player's table
  player_data.active_translations[dictionary_name] = {
    -- string registry index
    registry_index = registry_index,
    registry_index_size = table_size(registry_index), -- used to determine when the translation has finished
    -- options
    convert_to_lowercase = options.convert_to_lowercase,
    include_failed_translations = options.include_failed_translations,
    -- output
    lookup = {},
    sorted_results = {},
    translations = {}
  }

  -- increment active translations counters, register on_tick and sort result handlers
  __translation.active_translations_count = __translation.active_translations_count + 1
  player_data.active_translations_count = player_data.active_translations_count + 1
  -- raise translation start event
  event.raise(translation.start_event, {player_index=player.index, dictionary_name=dictionary_name})
  -- register events, if needed
  event.on_tick(translate_batch, {name='translation_translate_batch', player_index=player.index, skip_validation=true, suppress_logging=true})
  event.on_string_translated(sort_translated_string, {name='translation_sort_result', player_index=player.index, skip_validation=true, suppress_logging=true})
end

-- cancel a translation
function translation.cancel(player, dictionary_name)
  local __translation = global.__lualib.translation
  local player_data = __translation.players[player.index]
  local translation_data = player_data.active_translations[dictionary_name]
  if not translation_data then
    error('Tried to cancel a translation that isn\'t running!')
  end
  
  -- remove this dictionary from the string registry
  local string_registry = player_data.string_registry
  for key,_ in pairs(translation_data.registry_index) do
    local key_registry = string_registry[key]
    key_registry[dictionary_name] = nil
    if table_size(key_registry) == 0 then
      string_registry[key] = nil
    end
  end

  -- decrement active translation counters
  __translation.active_translations_count = __translation.active_translations_count - 1
  player_data.active_translations_count = player_data.active_translations_count - 1
  -- raise canceled event with the output tables
  event.raise(translation.canceled_event, {player_index=player.index, dictionary_name=dictionary_name})
  -- remove from active translations table
  player_data.active_translations[dictionary_name] = nil

  -- check if the player is done translating
  if player_data.active_translations_count == 0 then
    -- deregister events for this player
    event.deregister(defines.events.on_string_translated, sort_translated_string, 'translation_sort_result', player.index)
    event.deregister(defines.events.on_tick, translate_batch, 'translation_translate_batch', player.index)
    -- reset for the next time stuff is translated
    player_data.next_index = 0
    player_data.strings = {}
    player_data.strings_len = 0
  end
end

-- cancels all translations for a player
function translation.cancel_all_for_player(player)
  local __translation = global.__lualib.translation
  local player_translations = __translation.players[player.index].active_translations
  for name,_ in pairs(player_translations) do
    translation.cancel(player, name)
  end
end

-- cancels ALL translations for this mod
function translation.cancel_all()
  for i,t in pairs(global.__lualib.translation.players) do
    local player = game.get_player(i)
    for name,_ in pairs(t.active_translations) do
      translation.cancel(player, name)
    end
  end
end

-- sets up the player's data table
local function setup_player(index)
  global.__lualib.translation.players[index] = {
    active_translations = {}, -- contains data for each dictionary that is being translated
    active_translations_count = 0, -- count of translations that this player is performing
    next_index = 1, -- index of the next string to be translated
    string_registry = {}, -- contains data on where a translation should be placed
    strings = {}, -- contains the actual localised string objects to be translated
    strings_len = 0 -- length of the strings table, for use in on_tick to avoid extraneous logic
  }
end

-- remote interface for cross-mod sync
local function setup_remote()
  if not remote.interfaces['railualib_translation'] then -- create the interface
    remote.add_interface('railualib_translation', {
      retranslate_all_event = function() return event.generate_id('retranslate_all_event') end,
    })
    commands.add_command(
      'retranslate-all-dictionaries',
      '- retranslates all of your personal dictionaries',
      function(e)
        event.raise(translation.retranslate_all_event, {player_index=e.player_index})
      end
    )
  end
  translation.retranslate_all_event = remote.call('railualib_translation', 'retranslate_all_event')
end

-- set up global
event.on_init(function()
  if not global.__lualib then global.__lualib = {} end
  global.__lualib.translation = {
    active_translations_count = 0,
    players = {}
  }
  for _,p in pairs(game.connected_players) do
    setup_player(p.index)
  end
  setup_remote()
end)

-- re-register events if necessary
event.on_load(function()
  event.load_conditional_handlers{
    translation_translate_batch = translate_batch,
    translation_sort_result = sort_translated_string
  }
  setup_remote()
end)

-- set up player table
-- the player's table will be completely destroyed when they exit, so we create it in on_player_joined_game
event.on_player_joined_game(function(e)
  -- if we load a singleplayer game and become someone else, we must first cancel any ongoing translations that they were doing
  if global.__lualib.translation.players[e.player_index] then
    translation.cancel_all_for_player(game.get_player(e.player_index))
  end
  setup_player(e.player_index)
end, {insert_at_front=true}) -- guarantee that this will be run first to avoid crashes later on

-- cancel all translations for the player and destroy their global data
event.on_player_left_game(function(e)
  local player_translation = global.__lualib.translation.players[e.player_index]
  if player_translation.active_translations_count > 0 then
    translation.cancel_all_for_player(game.get_player(e.player_index))
    global.__lualib.translation.players[e.player_index] = nil
  end
end)

return translation