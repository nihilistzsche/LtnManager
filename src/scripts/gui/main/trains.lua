local trains_tab = {}

function trains_tab.build()
  return {
    tab = {type = "tab", caption = {"gui.ltnm-trains"}, ref = {"trains", "tab"}},
    content = {type = "empty-widget", style_mods = {width = 1000, height = 700}}
  }
end

function trains_tab.init()
end

function trains_tab.refresh(refs, state)
end

return trains_tab
