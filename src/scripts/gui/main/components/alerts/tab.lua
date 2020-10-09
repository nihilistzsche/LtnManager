local component = {}

function component.view()
  return (
    {
      tab = {type = "tab", caption = {"ltnm-gui.alerts"}},
      content = (
        {type = "empty-widget"}
      )
    }
  )
end

return component