local dictionary = require("__flib__.dictionary")

local constants = require("constants")

local global_data = {}

function global_data.init()
  global.flags = {
    deleted_all_alerts = false,
    deleted_history = false,
    iterating_ltn_data = false,
    updating_guis = false,
  }
  global.players = {}
end

function global_data.build_dictionaries()
  -- GUI
  dictionary.new("gui", true, constants.gui_translations)

  -- Materials
  local Materials = dictionary.new("materials", true)
  for _, type in ipairs({ "fluid", "item" }) do
    local prefix = type .. ","
    for name, prototype in pairs(game[type .. "_prototypes"]) do
      Materials:add(prefix .. name, prototype.localised_name)
    end
  end

  -- Virtual signals
  local VirtualSignals = dictionary.new("virtual_signals", true)
  for name, prototype in pairs(game.virtual_signal_prototypes) do
    VirtualSignals:add(name, prototype.localised_name)
  end
end

return global_data
