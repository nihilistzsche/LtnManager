local dictionary = require("__flib__.dictionary")

local player_data = {}

function player_data.init(player, index)
  local player_table = {
    dictionaries = nil,
    flags = {
      can_open_gui = false,
      translate_on_join = false,
      translations_finished = false
    },
    guis = {},
    last_update = game.tick,
  }
  player.set_shortcut_available("ltnm-toggle-gui", false)
  global.players[index] = player_table
end

function player_data.refresh(player, player_table)
  -- TODO: destroy GUIs

  -- set flags
  player_table.flags.can_open_gui = false
  player_table.flags.translations_finished = false

  player.set_shortcut_toggled("ltnm-toggle-gui", false)
  player.set_shortcut_available("ltnm-toggle-gui", false)

  player_table.dictionaries = nil
  if player.connected then
    dictionary.translate(player)
  end
end

function player_data.set_setting(player_index, setting_name, setting_value)
  local player = game.get_player(player_index)
  player.mod_settings["ltnm-"..setting_name] = {value = setting_value}
end

return player_data
