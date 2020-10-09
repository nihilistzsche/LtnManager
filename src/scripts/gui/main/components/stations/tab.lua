local component = {}

function component.view()
  return (
    {
      tab = {type = "tab", caption = {"ltnm-gui.stations"}},
      content = (
        {type = "empty-widget"}
      )
    }
  )
end

return component