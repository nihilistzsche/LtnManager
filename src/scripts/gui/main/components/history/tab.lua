local component = {}

function component.view()
  return (
    {
      tab = {type = "tab", caption = {"ltnm-gui.history"}},
      content = (
        {type = "empty-widget"}
      )
    }
  )
end

return component