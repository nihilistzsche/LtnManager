local gui = require("__flib__.gui")
local translation = require("__flib__.translation")

return {
  ["0.2.0"] = function()
    gui.init()
    translation.init()

    global.__lualib = nil
    global.flags.iterating_ltn_data = false
    global.flags.opening_search = false
    global.flags.search_open = false
    global.flags.updating_guis = false

    local tick = game.tick
    for i in pairs(game.players) do
      local player_table = global.players[i]
      player_table.dictionary = nil
      player_table.last_update = tick
    end
  end
}