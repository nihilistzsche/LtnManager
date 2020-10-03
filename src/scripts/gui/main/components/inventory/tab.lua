local component = require("lib.gui-component")()

function component.build()
  return (
    {
      type = "tab-and-content",
      tab = {type = "tab", caption = {"ltnm-gui.inventory"}},
      content = (
        {type = "empty-widget"}
      )
    }
  )
end

return component