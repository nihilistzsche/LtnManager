local gui = require("__flib__.gui3")

local component = gui.component()

function component.build()
  return (
    {
      type = "tab-and-content",
      tab = {type = "tab", caption = {"ltnm-gui.alerts"}},
      content = (
        {type = "empty-widget"}
      )
    }
  )
end

return component