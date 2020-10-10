local gui = require("__flib__.gui3")

local root = require("scripts.gui.main.components.root")

local main_gui = {}

function main_gui.create(player, player_table)
  -- create GUI
  player_table.gui.Main = gui.new(root, player.gui.screen)

  -- set flag and shortcut state
  player_table.flags.can_open_gui = true
  player.set_shortcut_available("ltnm-toggle-gui", true)
end

function main_gui.destroy(player, player_table)
  -- destroy and remove GUI from player table
  player_table.gui.Main:destroy()
  player_table.gui.Main = nil

  -- set flag and shortcut state
  player_table.flags.can_open_gui = false
  player.set_shortcut_available("ltnm-toggle-gui", false)
end

function main_gui.toggle(player_index, player_table)
  local MainGui = player_table.gui.Main
  local action = MainGui.state.base.visible and "close" or "open"
  MainGui:dispatch({comp = "base", action = action}, {player_index = player_index})
end

function main_gui.update(player_index, player_table)
  player_table.gui.Main:dispatch({update_ltn_data = true}, {player_index = player_index})
end

return main_gui