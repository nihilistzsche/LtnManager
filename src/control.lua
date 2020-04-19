-- -------------------------------------------------------------------------------------------------------------------------------------------------------------
-- CONTROL SCRIPTING

-- dependencies
local event = require("__RaiLuaLib__.lualib.event")
local migration = require("__RaiLuaLib__.lualib.migration")
local translation = require("__RaiLuaLib__.lualib.translation")

-- scripts
local alert_popup_gui = require("gui.alert-popup")
local data_manager = require("scripts.data-manager")
local main_gui = require("gui.main")

-- locals
local string_gsub = string.gsub
local string_sub = string.sub

-- globals
function UPDATE_MAIN_GUI(player, player_table, state_changes)
  main_gui.update(player, player_table, state_changes)
end

-- -----------------------------------------------------------------------------
-- TRANSLATIONS

local function build_translation_data()
  local translation_data = {
    gui = {
      -- train status
      {internal="delivering-to", localised={"ltnm-gui.delivering-to"}},
      {internal="fetching-from", localised={"ltnm-gui.fetching-from"}},
      {internal="loading-at", localised={"ltnm-gui.loading-at"}},
      {internal="parked-at-depot", localised={"ltnm-gui.parked-at-depot"}},
      {internal="returning-to-depot", localised={"ltnm-gui.returning-to-depot"}},
      {internal="unloading-at", localised={"ltnm-gui.unloading-at"}}
    },
    materials = {}
  }
  -- materials
  for _, type in ipairs{"fluid", "item"} do
    local prefix = type..","
    for name, prototype in pairs(game[type.."_prototypes"]) do
      translation_data.materials[#translation_data.materials+1] = {internal=prefix..name, localised=prototype.localised_name}
    end
  end
  global.__lualib.translation.translation_data = translation_data
end

local function run_player_translations(player)
  local translation_data = global.__lualib.translation.translation_data
  for _, name in ipairs{"materials", "gui"} do
    translation.start(player, name, translation_data[name], {include_failed_translations=true})
  end
end

-- -----------------------------------------------------------------------------
-- PLAYER DATA

local function setup_player(player, index)
  local data = {
    dictionary = {},
    flags = {
      can_open_gui = false,
      gui_open = false,
      translate_on_join = false,
      translations_finished = false
    },
    gui = {}
  }
  player.set_shortcut_available("ltnm-toggle-gui", false)
  global.players[index] = data
end

local function destroy_player_guis(player, player_table)
  if player_table.gui.main then
    main_gui.close(player, player_table)
    main_gui.destroy(player, player_table)
  end
  if player_table.gui.alert_popup then
    alert_popup_gui.destroy(player, player_table)
  end
end

local function update_player_settings(player, player_table)
  local settings = {}
  for name, t in pairs(player.mod_settings) do
    if string_sub(name, 1,5) == "ltnm-" then
      name = string_gsub(name, "ltnm%-", "")
      settings[string_gsub(name, "%-", "_")] = t.value
    end
  end
  player_table.settings = settings
end

-- completely close all GUIs, update settings, and retranslate
local function refresh_player_data(player, player_table)
  -- destroy GUIs
  destroy_player_guis(player, player_table)

  -- set shortcut state
  player_table.flags.translations_finished = false
  player.set_shortcut_available("ltnm-toggle-gui", false)

  -- update settings
  update_player_settings(player, player_table)

  -- run translations
  player_table.dictionary = {}
  if player.connected then
    run_player_translations(player)
  else
    player_table.flags.translate_on_join = true
  end
end

-- -----------------------------------------------------------------------------
-- CONDITIONAL EVENTS

-- tied to LTN on_dispatcher_updated
local function enable_gui(e)
  local players = global.players
  for _, i in pairs(e.registered_players) do
    local player = game.get_player(i)
    main_gui.create(player, players[i])
    players[i].flags.can_open_gui = true
    player.set_shortcut_available("ltnm-toggle-gui", true)
    event.disable("enable_gui_on_next_ltn_update", i)
  end
end

-- auto-update GUIs for all registered players
local function auto_update_guis(e)
  local players = global.players
  for _, i in ipairs(e.registered_players) do
    local player_table = players[i]
    -- only update if they have the GUI open
    if player_table.flags.gui_open then
      main_gui.update_active_tab(game.get_player(i), player_table)
    end
  end
end

-- -----------------------------------------------------------------------------
-- STATIC EVENTS

event.on_init(function()
  global.flags = {}
  global.players = {}
  global.working_data = {history={}, alerts={_index=0}, alert_popups={}}
  build_translation_data()
  for i, p in pairs(game.players) do
    setup_player(p, i)
    refresh_player_data(p, global.players[i])
  end
  data_manager.setup_events()
  event.enable_group("ltn")
end)

event.on_load(function()
  data_manager.setup_events()
end)

event.on_player_created(function(e)
  local player = game.get_player(e.player_index)
  setup_player(player, e.player_index)
  refresh_player_data(player, global.players[e.player_index])
end)

event.on_player_removed(function(e)
  global.players[e.player_index] = nil
end)

event.on_player_joined_game(function(e)
  local player_table = global.players[e.player_index]
  if player_table.flags.translate_on_join then
    player_table.flags.translate_on_join = false
    run_player_translations(game.get_player(e.player_index))
  end
end)

event.on_runtime_mod_setting_changed(function(e)
  if string_sub(e.setting, 1, 5) == "ltnm-" then
    for i, p in pairs(game.players) do
      update_player_settings(p, global.players[i])
    end
  end
end)

event.register({defines.events.on_lua_shortcut, "ltnm-toggle-gui"}, function(e)
  if e.input_name or (e.prototype_name == "ltnm-toggle-gui") then
    local player = game.get_player(e.player_index)
    local player_table = global.players[e.player_index]
    if player_table.flags.can_open_gui then
      main_gui.toggle(player, player_table)
    else
      player.print{"ltnm-message.cannot-open-gui"}
    end
  end
end)

event.register(translation.finish_event, function(e)
  local player_table = global.players[e.player_index]
  -- add to player table
  player_table.dictionary[e.dictionary_name] = {
    translations = e.translations
  }
  -- if this player is done translating
  if global.__lualib.translation.players[e.player_index].active_translations_count == 0 then
    -- enable opening the GUI on the next LTN update cycle
    player_table.flags.translations_finished = true
    event.enable("enable_gui_on_next_ltn_update", e.player_index)
  end
end)

-- LTN and retranslate events don't exist in the root scope, so register them in bootstrap
event.register({"on_init", "on_load"}, function()
  event.register_conditional{
    enable_gui_on_next_ltn_update = {id=data_manager.ltn_event_ids.on_dispatcher_updated, handler=enable_gui},
    auto_refresh = {id=-300, handler=auto_update_guis}
  }
  event.register(translation.retranslate_all_event, function(e)
    local player = game.get_player(e.player_index)
    local player_table = global.players[e.player_index]
    refresh_player_data(player, player_table)
  end)
end)

-- mod debugging / fixing commands
commands.add_command("LtnManager", " [parameter]\nrefresh_player_data - close and recreate all GUIs, retranslate dictionaries, and update settings",
  function(e)
    if e.parameter == "refresh_player_data" then
      refresh_player_data(game.get_player(e.player_index), global.players[e.player_index])
    end
  end
)

-- -----------------------------------------------------------------------------
-- MIGRATIONS

-- table of migration functions
local migrations = {
  ["0.1.3"] = function()
    event.enable("on_train_created")
  end
}

event.on_configuration_changed(function(e)
  if migration.on_config_changed(e, migrations) then
    -- update translation data
    build_translation_data()
    -- refresh all player information
    for i, p in pairs(game.players) do
      refresh_player_data(p, global.players[i])
    end
    -- reset LTN data iteration
    data_manager.reset()
  end
end)
