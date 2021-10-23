local event = require("__flib__.event")
local dictionary = require("__flib__.dictionary")
local gui = require("__flib__.gui")
local migration = require("__flib__.migration")

local global_data = require("scripts.global-data")
local ltn_data = require("scripts.ltn-data")
local migrations = require("scripts.migrations")
local player_data = require("scripts.player-data")

local main_gui = require("scripts.gui.main.base")

-- -----------------------------------------------------------------------------
-- COMMANDS

commands.add_command("LtnManager", {"ltnm-message.command-help"},
  function(e)
    if e.parameter == "refresh-player-data" then
      local player = game.get_player(e.player_index)
      local player_table = global.players[e.player_index]
      player_data.refresh(player, player_table)
    end
  end
)

-- -----------------------------------------------------------------------------
-- EVENT HANDLERS
-- LTN data handlers are kept in `scripts.ltn-data`
-- all other handlers are kept here

-- BOOTSTRAP

event.on_init(function()
  dictionary.init()

  global_data.init()
  global_data.build_dictionaries()

  ltn_data.init()
  ltn_data.connect()

  for i, player in pairs(game.players) do
    player_data.init(player, i)
    player_data.refresh(player, global.players[i])
  end
end)

event.on_load(function()
  dictionary.load()
  ltn_data.connect()
end)

event.on_configuration_changed(function(e)
  if migration.on_config_changed(e, migrations) then
    dictionary.init()

    global_data.build_translations()
    ltn_data.init()

    for i, player in pairs(game.players) do
      player_data.refresh(player, global.players[i])
    end
  end
end)

-- GUI

gui.hook_events(function(e)
  local msg = gui.read_action(e)
  if msg then
    if msg.gui == "main" then
      main_gui.handle_action(e, msg)
    end
  end
end)

-- PLAYER

event.on_player_created(function(e)
  local player = game.get_player(e.player_index)
  player_data.init(player, e.player_index)
  player_data.refresh(player, global.players[e.player_index])
end)

event.on_player_removed(function(e)
  global.players[e.player_index] = nil
end)

event.on_player_joined_game(function(e)
  local player = game.get_player(e.player_index)
  if player.connected then
    dictionary.translate(player)
  end
end)

event.on_player_left_game(function(e)
  dictionary.cancel_translation(e.player_index)
end)

-- SHORTCUT

event.register({defines.events.on_lua_shortcut, "ltnm-toggle-gui"}, function(e)
  if e.input_name or (e.prototype_name == "ltnm-toggle-gui") then
    local player = game.get_player(e.player_index)
    local player_table = global.players[e.player_index]
    local flags = player_table.flags
    if flags.can_open_gui then
      main_gui.toggle(player, player_table)
    else
      -- close GUI if it is open (just in case)
      local gui_data = player_table.guis.main
      if gui_data and gui_data.state.visible == true then
        main_gui.close(player, player_table)
      end
      -- print warning message
      if flags.translations_finished then
        player.print{"ltnm-message.ltn-no-data"}
      else
        player.print{"ltnm-message.translations-not-finished"}
      end
    end
  end
end)

-- SETTINGS

event.on_runtime_mod_setting_changed(function(e)
  if string.sub(e.setting, 1, 5) == "ltnm-" then
    for i, p in pairs(game.players) do
      player_data.update_settings(p, global.players[i])
    end
  end
end)

-- TICK

event.on_tick(function(e)
  local flags = global.flags

  if flags.iterating_ltn_data then
    ltn_data.iterate()
  end

  if flags.updating_guis then
    local player_index = global.next_update_index
    local player = game.get_player(player_index)
    local player_table = global.players[player_index]
    local player_flags = player_table.flags
    if player_flags.translations_finished and not player_flags.can_open_gui then
      main_gui.build(player, player_table)
    elseif
      player_table.flags.can_open_gui
      -- TODO:
      -- and player_table.gui.main.state.base.visible
      -- and player_table.gui.main.state.base.auto_refresh
    then
      -- TODO: update GUI LTN data
    end

    -- get and save next index, or stop iteration
    local next_index = next(global.players, global.next_update_index)
    if next_index then
      global.next_update_index = next_index
    else
      global.next_update_index = nil
      flags.updating_guis = false
    end
  end

  dictionary.check_skipped()
end)

-- TRANSLATIONS

event.on_string_translated(function(e)
  local language_data = dictionary.process_translation(e)
  if language_data then
    for _, player_index in pairs(language_data.players) do
      local player_table = global.players[player_index]
      -- If the player already has a language, replace it and rebuild the GUI
      if player_table.dictionaries and (player_table.language or "") ~= language_data.language then
        player_table.language = language_data.language
        player_table.dictionaries = language_data.dictionaries
        -- TODO: Refresh GUI
      elseif not player_table.flags.can_open_gui then
        player_table.language = language_data.language
        player_table.dictionaries = language_data.dictionaries
        -- Enable opening the GUI on the next LTN update cycle
        player_table.flags.translations_finished = true
      end
    end
  end
end)
