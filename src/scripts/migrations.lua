local gui = require("__flib__.control.gui")
local translation = require("__flib__.control.translation")

return {
  ["0.2.0"] = function()
    gui.init()
    translation.init()

    global.__lualib = nil
    global.flags.iterating_ltn_data = false
    global.flags.updating_guis = false

    local tick = game.tick
    for _, player_table in pairs(game.players) do
      player_table.last_update = tick
    end
  end
}