local component = require("lib.gui-component")()

component.base_template = (
  {
    type = "tab-and-content",
    tab = {type = "tab", caption = {"ltnm-gui.depots"}},
    content = (
      {type = "empty-widget", style_mods = {width = 800, height = 500}}
    )
  }
)

return component