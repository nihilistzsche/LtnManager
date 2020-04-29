local event = require("__flib__.control.event")
local gui = require("__flib__.control.gui")
local migration = require("__flib__.control.migration")
local translation = require("__flib__.control.translation")

local alert_popup_gui = require("scripts.gui.alert-popup")
local global_data = require("scripts.global-data")
local ltn_data = require("scripts.ltn-data")
local main_gui = require("scripts.gui.main")
local migrations = require("scripts.migrations")
local player_data = require("scripts.player-data")

local string_sub = string.sub

function UPDATE_MAIN_GUI(player, player_table, state_changes)
  main_gui.update(player, player_table, state_changes)
end

-- -----------------------------------------------------------------------------
-- COMMANDS

commands.add_command("LtnManager", {"ltnm-message.command-help"},
  function(e)
    if e.parameter == "refresh-player-data" then
      local player = game.get_player(e.player_index)
      local player_table = global.players[e.player_index]
      if player_table.gui.main then
        main_gui.close(player, player_table)
        main_gui.destroy(player, player_table)
      end
      if player_table.gui.alert_popup then
        alert_popup_gui.destroy(player, player_table)
      end
      player_data.refresh(game.get_player(e.player_index), player_table)
    end
  end
)

-- -----------------------------------------------------------------------------
-- EVENT HANDLERS

-- BOOTSTRAP

event.on_init(function()
  gui.init()
  translation.init()

  global_data.init()
  ltn_data.init()
  ltn_data.setup_events()

  gui.bootstrap_postprocess()
end)

event.on_load(function()
  ltn_data.setup_events()
  gui.bootstrap_postprocess()
end)

event.on_configuration_changed(function(e)
  if migration.on_config_changed(e, migrations) then
    -- update translation data
    global_data.build_translations()
    -- refresh all player information
    for i, player in pairs(game.players) do
      local player_table = global.players[i]
      if player_table.gui.main then
        main_gui.close(player, player_table)
        main_gui.destroy(player, player_table)
      end
      if player_table.gui.alert_popup then
        alert_popup_gui.destroy(player, player_table)
      end
      player_data.refresh(player, player_table)
    end
    -- reset LTN data iteration
    ltn_data.reset()
  end
end)

-- GUI

gui.register_events()

-- PLAYER

event.on_player_created(function(e)
  local player = game.get_player(e.player_index)
  player_data.setup(player, e.player_index)
  player_data.refresh(player, global.players[e.player_index])
end)

event.on_player_removed(function(e)
  global.players[e.player_index] = nil
end)

event.on_player_joined_game(function(e)
  local player_table = global.players[e.player_index]
  if player_table.flags.translate_on_join then
    player_table.flags.translate_on_join = false
    player_data.start_translations(e.player_index)
  end
end)

-- SHORTCUT

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

-- SETTINGS

event.on_runtime_mod_setting_changed(function(e)
  if string_sub(e.setting, 1, 5) == "ltnm-" then
    for i, p in pairs(game.players) do
      player_data.update_settings(p, global.players[i], e.setting)
    end
  end
end)

-- TICK

event.on_tick(function()
  local flags = global.flags
  if flags.iterating_ltn_data then
    ltn_data.iterate()
  end
  if global.__flib.translation.active_translations_count > 0 then
    translation.translate_batch()
  end
end)

-- TRANSLATIONS

event.on_string_translated(translation.sort_string)

translation.on_finished(function(e)
  local player_table = global.players[e.player_index]
  -- add to player table
  player_table.dictionary[e.dictionary_name] = {
    translations = e.translations
  }
  -- if this player is done translating
  if global.__flib.translation.players[e.player_index].active_translations_count == 0 then
    -- enable opening the GUI on the next LTN update cycle
    player_table.flags.translations_finished = true
  end
end)