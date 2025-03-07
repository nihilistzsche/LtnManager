local dictionary = require("lib.dictionary")
local gui = require("lib.gui")
local on_tick_n = require("__flib__.on-tick-n")

local global_data = require("scripts.storage-data")
local ltn_data = require("scripts.ltn-data")
local player_data = require("scripts.player-data")

return {
  ["1.0.0"] = function()
    -- Nuke everything
    storage = {}

    -- Reinitialize
    dictionary.init()
    on_tick_n.init()

    global_data.init()
    global_data.build_dictionaries()

    ltn_data.init()
    ltn_data.connect()

    for i, player in pairs(game.players) do
      player_data.init(player, i)
      player_data.refresh(player, storage.players[i])
    end
  end,
}
