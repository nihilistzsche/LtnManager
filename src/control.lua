local event = require("__flib__.event")
local gui = require("__flib__.gui")
local migration = require("__flib__.migration")
local translation = require("__flib__.translation")

local constants = require("constants")

local alert_popup_gui = require("scripts.gui.alert-popup")
local global_data = require("scripts.global-data")
local ltn_data = require("scripts.ltn-data")
local main_gui = require("scripts.gui.main")
local migrations = require("scripts.migrations")
local player_data = require("scripts.player-data")

local string_sub = string.sub

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

local function setup_ltn_handlers()
  if not remote.interfaces["logistic-train-network"] then
    error("Could not establish connection to LTN!")
  end
  for event_name in pairs(constants.ltn_event_names) do
    local id = remote.call("logistic-train-network", event_name)
    ltn_data.event_ids[event_name] = id
    event.register(id, ltn_data[event_name])
  end
  event.on_train_created(ltn_data.on_train_created)
end

-- BOOTSTRAP

event.on_init(function()
  gui.init()
  translation.init()

  global_data.init()
  ltn_data.init()

  setup_ltn_handlers()

  for i, player in pairs(game.players) do
    player_data.init(player, i)
    player_data.refresh(player, global.players[i])
  end

  gui.build_lookup_tables()
end)

event.on_load(function()
  setup_ltn_handlers()

  gui.build_lookup_tables()
end)

event.on_configuration_changed(function(e)
  if migration.on_config_changed(e, migrations) then
    -- update translation data
    global_data.build_translations()
    -- reset LTN data
    ltn_data.init()
    -- refresh all player information
    for i, player in pairs(game.players) do
      -- close open GUIs
      local player_table = global.players[i]
      if player_table.gui.main then
        main_gui.close(player, player_table)
        main_gui.destroy(player, player_table)
      end
      if player_table.gui.alert_popup then
        alert_popup_gui.destroy(player, player_table)
      end
      -- refresh data
      player_data.refresh(player, player_table)
    end
  end
end)

-- GUI

gui.register_handlers()

event.register("ltnm-search", function(e)
  local player_table = global.players[e.player_index]
  if player_table.flags.gui_open then
    main_gui.toggle_search(game.get_player(e.player_index), player_table)
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
  local player_table = global.players[e.player_index]
  if player_table.flags.translate_on_join then
    player_table.flags.translate_on_join = false
    player_data.start_translations(e.player_index)
  end
end)

event.on_player_left_game(function(e)
  if translation.is_translating(e.player_index) then
    translation.cancel(e.player_index)
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
    local player_table = global.players[player_index]
    local player_flags = player_table.flags
    if player_flags.translations_finished and not player_flags.can_open_gui then
      -- create GUI
      local player = game.get_player(player_index)
      main_gui.create(player, player_table)
      player_flags.can_open_gui = true
      player.set_shortcut_available("ltnm-toggle-gui", true)
    elseif player_table.flags.gui_open and player_table.settings.auto_refresh and game.tick - player_table.last_update >= 180 then
      -- update GUI
      main_gui.update_active_tab(game.get_player(player_index), player_table)
      player_table.last_update = game.tick
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

  if translation.translating_players_count() > 0 then
    translation.iterate_batch(e)
  end
end)

-- TRANSLATIONS

event.on_string_translated(function(e)
  local names, finished = translation.process_result(e)
  local player_table = global.players[e.player_index]
  if names then
    local translations = player_table.translations
    for dictionary_name, internal_names in pairs(names) do
      local dictionary = translations[dictionary_name]
      for i = 1, #internal_names do
        dictionary[internal_names[i]] = e.translated and e.result or internal_names[i]
      end
    end
  end
  if finished then
    -- enable opening the GUI on the next LTN update cycle
    player_table.flags.translations_finished = true
  end
end)