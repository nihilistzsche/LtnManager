local gui = require("__flib__.gui")
local translation = require("__flib__.translation")

return {
  ["0.2.0"] = function()
    gui.init()
    translation.init()

    global.__lualib = nil
    global.flags.iterating_ltn_data = false
    global.flags.updating_guis = false

    local tick = game.tick
    for i in pairs(game.players) do
      local player_table = global.players[i]
      player_table.dictionary = nil
      player_table.flags.search_open = false
      player_table.flags.toggling_search = false
      player_table.last_update = tick
    end
  end,
  ["0.3.0"] = function()
    global.flags.deleted_all_alerts = false
    global.flags.deleted_history = false

    -- remove all alert popup GUIs
    for _, player_table in pairs(global.players) do
      local alert_popup = player_table.gui.alert_popup
      if player_table.gui.alert_popup then
        alert_popup.button.destroy()
        player_table.gui.alert_popup = nil
      end
    end
  end
}