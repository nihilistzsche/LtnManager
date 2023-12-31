local event = require("__flib__.event")
local dictionary = require("__flib__.dictionary")
local gui = require("__flib__.gui")
local migration = require("__flib__.migration")
local on_tick_n = require("__flib__.on-tick-n")

local global_data = require("scripts.global-data")
local ltn_data = require("scripts.ltn-data")
local migrations = require("scripts.migrations")
local player_data = require("scripts.player-data")

local main_gui = require("scripts.gui.index")

-- -----------------------------------------------------------------------------
-- COMMANDS

commands.add_command("LtnManager", { "ltnm-message.command-help" }, function(e)
  if e.parameter == "refresh-player-data" then
    local player = game.get_player(e.player_index)
    local player_table = global.players[e.player_index]
    player_data.refresh(player, player_table)
  end
end)

-- -----------------------------------------------------------------------------
-- INTERFACES

remote.add_interface("LtnManager", {
  --- Returns whether the LTN Manager GUI is open for the given player.
  --- @param player_index number
  --- @return boolean
  is_gui_open = function(player_index)
    if not player_index or type(player_index) ~= "number" then
      error("Must provide a valid player_index")
    end

    if global.players then
      local player_table = global.players[player_index]
      if player_table then
        local Gui = player_table.guis.main
        if Gui then
          return Gui.state.visible
        end
      end
    end

    return false
  end,
  --- Toggles the LTN Manager GUI for the given player, and returns its new state.
  --- @param player_index number
  --- @return boolean
  toggle_gui = function(player_index)
    if not player_index or type(player_index) ~= "number" then
      error("Must provide a valid player_index")
    end

    if global.players then
      local player_table = global.players[player_index]
      if player_table then
        local Gui = player_table.guis.main
        if Gui and Gui.refs.window.valid then
          Gui:toggle()
          return Gui.state.visible
        end
      end
    end

    return false
  end,
  get_provided_inventory_for_surface = function(surface_index)
    if not surface_index or type(surface_index) ~= "number" then
      error("Must provide a valid surface_index")
    end

    if not global.data or not global.data.inventory or not global.data.inventory.provided then
      return nil
    end

    return global.data.inventory.provided[surface_index]
  end,
})

-- -----------------------------------------------------------------------------
-- EVENT HANDLERS
-- LTN data handlers are kept in `scripts.ltn-data`
-- all other handlers are kept here

-- BOOTSTRAP

event.on_init(function()
  dictionary.init()
  on_tick_n.init()

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

  for _, player_table in pairs(global.players) do
    if player_table.guis and player_table.guis.main then
      main_gui.load(player_table.guis.main)
    end
  end
end)

event.on_configuration_changed(function(e)
  if migration.on_config_changed(e, migrations) then
    dictionary.init()

    global_data.build_dictionaries()
    ltn_data.init()

    for i, player in pairs(game.players) do
      player_data.refresh(player, global.players[i])
    end
  end
end)

-- GUI

local function handle_gui_event(msg, e)
  if msg.gui == "main" then
    local player_table = global.players[e.player_index]
    if player_table.flags.can_open_gui then
      local Gui = player_table.guis.main
      if Gui and Gui.refs.window.valid then
        Gui:dispatch(msg, e)
      end
    end
  end
end

gui.hook_events(function(e)
  local msg = gui.read_action(e)
  if msg then
    handle_gui_event(msg, e)
  end
end)

event.register("ltnm-linked-focus-search", function(e)
  local Gui = global.players[e.player_index].guis.main
  if Gui and Gui.state.visible and not Gui.state.pinned then
    handle_gui_event({ gui = "main", action = "focus_search" }, e)
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

event.register({ defines.events.on_lua_shortcut, "ltnm-toggle-gui" }, function(e)
  if e.input_name or (e.prototype_name == "ltnm-toggle-gui") then
    local player = game.get_player(e.player_index)
    local player_table = global.players[e.player_index]
    local flags = player_table.flags
    local Gui = main_gui.get(e.player_index)
    if Gui then
      if flags.can_open_gui then
        Gui:toggle()
      else
        if Gui.state.visible then
          Gui:close()
        end
        if flags.translations_finished then
          player.print({ "ltnm-message.ltn-no-data" })
        else
          player.print({ "ltnm-message.translations-not-finished" })
        end
      end
    end
  end
end)

-- TICK

event.on_tick(function(e)
  dictionary.check_skipped()

  local tasks = on_tick_n.retrieve(e.tick)
  if tasks then
    for _, task in pairs(tasks) do
      if task.gui then
        handle_gui_event(task, { player_index = task.player_index })
      end
    end
  end

  local flags = global.flags

  if flags.iterating_ltn_data then
    ltn_data.iterate()
  end

  if flags.updating_guis then
    local player_index = global.next_update_index
    local player = game.get_player(player_index)
    local player_table = global.players[player_index]
    local player_flags = player_table.flags
    if player_flags.translations_finished then
      if player_flags.can_open_gui then
        local Gui = main_gui.get(player_index)
        if Gui and Gui.state.visible and Gui.state.auto_refresh then
          Gui.state.ltn_data = global.data
          Gui:update()
        end
      else
        main_gui.build(player, player_table)
      end
    end

    local next_index = next(global.players, global.next_update_index)
    if next_index then
      global.next_update_index = next_index
    else
      global.next_update_index = nil
      flags.updating_guis = false
    end
  end
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
        -- TODO: Rebuild GUI
      elseif not player_table.flags.can_open_gui then
        player_table.language = language_data.language
        player_table.dictionaries = language_data.dictionaries
        -- Enable opening the GUI on the next LTN update cycle
        player_table.flags.translations_finished = true
      end
    end
  end
end)
