local component = require("lib.gui-component")()

component.template = (
  {
    type = "tab-and-content",
    tab = {type = "tab", caption = {"ltnm-gui.alerts"}},
    content = (
      {type = "empty-widget", style_mods = {width = 1000, height = 500}}
    )
  }
)

return component