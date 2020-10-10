local event = require("__flib__.event")
local gui = require("__flib__.gui3")
local migration = require("__flib__.migration")
local translation = require("__flib__.translation")

local global_data = require("scripts.global-data")
local ltn_data = require("scripts.ltn-data")
local main_gui = require("scripts.gui.main.controller")
local migrations = require("scripts.migrations")
local player_data = require("scripts.player-data")

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
  gui.init()
  translation.init()

  global_data.init()
  ltn_data.init()
  ltn_data.connect()

  for i, player in pairs(game.players) do
    player_data.init(player, i)
    player_data.refresh(player, global.players[i])
  end

end)

event.on_load(function()
  gui.load()
  ltn_data.connect()
end)

event.on_configuration_changed(function(e)
  if migration.on_config_changed(e, migrations) then
    -- migrate flib modules
    -- TODO
    -- gui.init()
    translation.init()
    -- update translation data
    global_data.build_translations()
    -- reset LTN data
    ltn_data.init()
    -- refresh all player information
    for i, player in pairs(game.players) do
      -- refresh data
      player_data.refresh(player, global.players[i])
    end
  end
end)

-- GUI

gui.register_handlers()

-- TODO
-- event.register("ltnm-search", function(e)
--   local player_table = global.players[e.player_index]
--   if player_table.flags.gui_open then
--     -- main_gui.toggle_search(game.get_player(e.player_index), player_table)
--   end
-- end)

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
    global.players[e.player_index].flags.translate_on_join = true
  end
end)

-- SHORTCUT

event.register({defines.events.on_lua_shortcut, "ltnm-toggle-gui"}, function(e)
  if e.input_name or (e.prototype_name == "ltnm-toggle-gui") then
    local player = game.get_player(e.player_index)
    local player_table = global.players[e.player_index]
    local flags = player_table.flags
    if flags.can_open_gui then
      main_gui.toggle(e.player_index, player_table)
    else
      -- close GUI if it is open (just in case)
      if player_table.gui.Main.state.base.visible then
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
    local player_table = global.players[player_index]
    local player_flags = player_table.flags
    if player_flags.translations_finished and not player_flags.can_open_gui then
      main_gui.create(game.get_player(player_index), player_table)
    elseif
      player_table.flags.can_open_gui
      and player_table.gui.Main.state.base.visible
      and player_table.gui.Main.state.base.auto_refresh
    then
      main_gui.update(player_index, player_table)
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