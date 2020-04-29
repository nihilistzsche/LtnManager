local gui = require("__flib__.control.gui")
local translation = require("__flib__.control.translation")

return {
  ["0.2.0"] = function()
    global.__lualib = nil
    gui.init()
    translation.init()
  end
}