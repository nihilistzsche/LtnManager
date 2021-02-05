local table = require("__flib__.table")
local translation = require("__flib__.translation")

local constants = require("constants")

local player_data = {}

function player_data.init(player, index)
  local player_table = {
    flags = {
      can_open_gui = false,
      translate_on_join = false,
      translations_finished = false
    },
    guis = {},
    last_update = game.tick,
    translations = table.shallow_copy(constants.empty_translation_tables)
  }
  player.set_shortcut_available("ltnm-toggle-gui", false)
  global.players[index] = player_table
end

function player_data.refresh(player, player_table)
  -- TODO: destroy GUIs

  -- set flags
  player_table.flags.can_open_gui = false
  player_table.flags.translations_finished = false

  -- set shortcut state
  player.set_shortcut_toggled("ltnm-toggle-gui", false)
  player.set_shortcut_available("ltnm-toggle-gui", false)

  -- run translations
  player_table.translations = table.shallow_copy(constants.empty_translation_tables)
  if player.connected then
    player_data.start_translations(player.index)
  else
    player_table.flags.translate_on_join = true
  end
end

function player_data.start_translations(player_index)
  translation.add_requests(player_index, global.translation_data)
end

function player_data.set_setting(player_index, setting_name, setting_value)
  local player = game.get_player(player_index)
  player.mod_settings["ltnm-"..setting_name] = {value = setting_value}
end

return player_data
