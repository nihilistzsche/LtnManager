local component = require("lib.gui-component")()

function component.build()
  return (
    {
      type = "tab-and-content",
      tab = {type = "tab", caption = {"ltnm-gui.stations"}},
      content = (
        {type = "empty-widget", width = 1000, height = 500}
      )
    }
  )
end

return component