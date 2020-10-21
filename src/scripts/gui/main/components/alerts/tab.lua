local gui = require("__flib__.gui-new")

local component = gui.component()

function component.update() end

function component.view()
  return (
    {
      tab = {type = "tab", caption = {"ltnm-gui.alerts"}, enabled = false},
      content = (
        {type = "empty-widget"}
      )
    }
  )
end

return component