local gui = require("__flib__.gui3")

local component = gui.component()

function component.update() end

function component.view()
  return (
    {
      tab = {type = "tab", caption = {"ltnm-gui.inventory"}},
      content = (
        {type = "empty-widget"}
      )
    }
  )
end

return component