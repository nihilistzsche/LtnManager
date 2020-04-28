local data = {}

local alert_popup_gui = require("scripts.gui.alert-popup")
local main_gui = require("scripts.gui.main")
local translation = require("__flib__.control.translation")

local string_gsub = string.gsub
local string_sub = string.sub

function data.setup_player(player, index)
  local player_data = {
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
  global.players[index] = player_data
end

function data.destroy_player_guis(player, player_table)
  -- if player_table.gui.main then
  --   main_gui.close(player, player_table)
  --   main_gui.destroy(player, player_table)
  -- end
  -- if player_table.gui.alert_popup then
  --   alert_popup_gui.destroy(player, player_table)
  -- end
end

function data.update_player_settings(player, player_table)
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
function data.refresh_player(player, player_table)
  -- destroy GUIs
  data.destroy_player_guis(player, player_table)

  -- set flags
  player_table.flags.can_open_gui = false
  player_table.flags.translations_finished = false

  -- set shortcut state
  -- player.set_shortcut_toggled("ltnm-toggle-gui", false)
  player.set_shortcut_available("ltnm-toggle-gui", false)

  -- update settings
  data.update_player_settings(player, player_table)

  -- run translations
  player_table.dictionary = {}
  if player.connected then
    data.start_translations(player.index)
  else
    player_table.flags.translate_on_join = true
  end
end

function data.build_translations()
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
  global.translation_data = translation_data
end

function data.start_translations(player_index)
  local translation_data = global.translation_data
  for _, name in ipairs{"materials", "gui"} do
    translation.start(player_index, name, translation_data[name], {include_failed_translations=true})
  end
end

function data.enable_gui(player_index, player_table)
  local player = game.get_player(player_index)
  player_table.flags.can_open_gui = true
  main_gui.create(player, player_table)
  player.set_shortcut_available("ltnm-toggle-gui", true)
end

-- INIT

function data.init()
  global.flags = {}
  global.players = {}
  data.build_translations()
  for i, p in pairs(game.players) do
    data.setup_player(p, i)
    data.refresh_player(p, global.players[i])
  end
end

return data