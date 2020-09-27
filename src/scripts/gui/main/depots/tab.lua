local component = require("lib.gui-component")()

local depot_select = require("scripts.gui.main.depots.depot-select")
local trains_list = require("scripts.gui.main.depots.trains-list")

component.template = (
  {
    type = "tab-and-content",
    tab = {type = "tab", caption = {"ltnm-gui.depots"}},
    content = (
      {type = "flow", style = "ltnm_tab_horizontal_flow", children = {
        depot_select(),
        trains_list()
      }}
    )
  }
)

return component