local gui = require("__flib__.gui-new")

local component = gui.component()

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