local dictionary = require("__flib__.dictionary")

local player_data = {}

function player_data.init(player, index)
  local player_table = {
    dictionaries = nil,
    flags = {
      can_open_gui = false,
      translate_on_join = false,
      translations_finished = false,
    },
    guis = {},
    language = nil,
    last_update = game.tick,
  }
  player.set_shortcut_available("ltnm-toggle-gui", false)
  global.players[index] = player_table
end

function player_data.refresh(player, player_table)
  local Gui = player_table.guis.main
  if Gui then
    Gui:destroy()
  end

  player_table.flags.can_open_gui = false
  player_table.flags.translations_finished = false

  player.set_shortcut_toggled("ltnm-toggle-gui", false)
  player.set_shortcut_available("ltnm-toggle-gui", false)

  player_table.dictionaries = nil
  if player.connected then
    dictionary.translate(player)
  end
end

return player_data
