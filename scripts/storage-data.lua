local dictionary = require("lib.dictionary")

local constants = require("constants")

local storage_data = {}

function storage_data.init()
  storage.flags = {
    deleted_all_alerts = false,
    deleted_history = false,
    iterating_ltn_data = false,
    updating_guis = false,
  }
  storage.players = {}
end

function storage_data.build_dictionaries()
  -- GUI
  dictionary.new("gui", true, constants.gui_translations)

  -- Materials
  local Materials = dictionary.new("materials", true)
  for _, type in ipairs({ "fluid", "item" }) do
    local prefix = type .. ","
    for name, prototype in pairs(prototypes[type]) do
      Materials:add(prefix .. name, prototype.localised_name)
    end
  end


  -- Virtual signals
  local VirtualSignals = dictionary.new("virtual_signals", true)
  for name, prototype in pairs(prototypes.virtual_signal) do
    VirtualSignals:add(name, prototype.localised_name)
  end
end

return storage_data
