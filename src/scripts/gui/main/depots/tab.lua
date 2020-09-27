local component = require("lib.gui-component")()

local depot_select = require("scripts.gui.main.depots.depot-select")

component.template = (
  {
    type = "tab-and-content",
    tab = {type = "tab", caption = {"ltnm-gui.depots"}},
    content = (
      {type = "flow", style = "ltnm_tab_horizontal_flow", children = {
        depot_select(),
        {type = "empty-widget", style = "flib_horizontal_pusher"}
      }}
    )
  }
)

return component