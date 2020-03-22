-- -------------------------------------------------------------------------------------------------------------------------------------------------------------
-- CONTROL SCRIPTING

-- dependencies
local event = require('__RaiLuaLib__.lualib.event')
local translation = require('__RaiLuaLib__.lualib.translation')
local util = require('scripts.util')

-- scripts
local data_manager = require('scripts.data-manager')
local main_gui = require('gui.main')
local migrations = require('scripts.migrations')

-- -----------------------------------------------------------------------------
-- UTILITIES

local function build_translation_data()
  local translation_data = {
    materials = {}
  }
  -- materials
  for _,type in ipairs{'fluid', 'item'} do
    local prefix = type..','
    for name,prototype in pairs(game[type..'_prototypes']) do
      translation_data.materials[#translation_data.materials+1] = {internal=prefix..name, localised=prototype.localised_name}
    end
  end
  -- gui
  translation_data.gui = {
    -- train status
    {internal='delivering-to', localised={'ltnm-gui.delivering-to'}},
    {internal='fetching-from', localised={'ltnm-gui.fetching-from'}},
    {internal='loading-at', localised={'ltnm-gui.loading-at'}},
    {internal='parked-at-depot', localised={'ltnm-gui.parked-at-depot'}},
    {internal='returning-to-depot', localised={'ltnm-gui.returning-to-depot'}},
    {internal='unloading-at', localised={'ltnm-gui.unloading-at'}},
    -- other
    {internal='search', localised={'ltnm-gui.search'}}
  }
  global.__lualib.translation.translation_data = translation_data
end

local function run_player_translations(player)
  player.set_shortcut_available('ltnm-toggle-gui', false)
  local translation_data = global.__lualib.translation.translation_data
  for _,name in ipairs{'materials', 'gui'} do
    translation.start(player, name, translation_data[name], {lowercase_sorted_translations=true, include_failed_translations=true})
  end
end

local function setup_player(player, index)
  local data = {
    dictionary = {},
    flags = {
      can_open_gui = false
    },
    gui = {}
  }
  global.players[index] = data
end

local function toggle_gui(e)
  local player = game.get_player(e.player_index)
  local player_table = global.players[e.player_index]
  -- toggle GUI
  if player_table.gui.main then
    main_gui.destroy(player, player_table)
  else
    if player_table.flags.can_open_gui then
      main_gui.create(player, player_table)
    else
      player.print{'ltnm-message.TEMP-COMEUPWITHANAMESTUPID!'}
    end
  end
  -- set shortcut state
  player.set_shortcut_toggled('ltnm-toggle-gui', player_table.gui.main and true or false)
end

-- registered conditionally, tied to the LTN on_stops_updated event
local function enable_gui(e)
  local players = global.players
  for _,i in pairs(e.registered_players) do
    players[i].flags.can_open_gui = true
    game.get_player(i).set_shortcut_available('ltnm-toggle-gui', true)
    event.disable('enable_gui_on_next_ltn_update', i)
  end
end

-- auto-update GUIs for all registered players
local function auto_update_guis(e)
  local players = global.players
  for _,i in ipairs(e.registered_players) do
    local player_table = players[i]
    -- only update if they have the GUI open
    if player_table.gui.main then
      main_gui.update_active_tab(game.get_player(i), player_table)
    end
  end
end

-- -----------------------------------------------------------------------------
-- EVENTS

event.on_init(function()
  global.flags = {}
  global.players = {}
  global.working_data = {history={}, alerts={}}
  build_translation_data()
  for i,p in pairs(game.players) do
    setup_player(p, i)
    if p.connected then
      run_player_translations(p)
    end
  end
  data_manager.setup_events()
  data_manager.enable_events()
end)

event.on_load(function()
  data_manager.setup_events()
end)

event.register({'on_init', 'on_load'}, function()
  event.register_conditional{
    enable_gui_on_next_ltn_update = {id=data_manager.ltn_event_ids.on_dispatcher_updated, handler=enable_gui},
    auto_refresh = {id=-300, handler=auto_update_guis}
  }
end)

event.on_configuration_changed(migrations)

event.on_player_created(function(e)
  setup_player(game.get_player(e.player_index), e.player_index)
end)

event.on_player_removed(function(e)
  global.players[e.player_index] = nil
end)

event.on_player_joined_game(function(e)
  local player_table = global.players[e.player_index]
  player_table.flags.can_open_gui = false
  run_player_translations(game.get_player(e.player_index))
end)

event.register({defines.events.on_lua_shortcut, 'ltnm-toggle-gui'}, function(e)
  if e.input_name or (e.prototype_name == 'ltnm-toggle-gui') then
    toggle_gui(e)
  end
end)

event.register(translation.finish_event, function(e)
  local player_table = global.players[e.player_index]
  -- add to player table
  player_table.dictionary[e.dictionary_name] = {
    lookup = e.lookup,
    lookup_lower = e.lookup_lower,
    sorted_translations = e.sorted_translations,
    translations = e.translations
  }
  -- if this player is done translating
  if global.__lualib.translation.players[e.player_index].active_translations_count == 0 then
    -- enable opening the GUI on the next LTN update cycle
    event.enable('enable_gui_on_next_ltn_update', e.player_index)
  end
end)

event.register(translation.retranslate_all_event, function(e)
  -- TODO: close GUIs and retranslate all
end)