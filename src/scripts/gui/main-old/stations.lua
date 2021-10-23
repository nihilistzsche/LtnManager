local stations_tab = {}

function stations_tab.build()
  return {
    tab = {type = "tab", caption = {"gui.ltnm-stations"}, enabled = false, ref = {"stations", "tab"}},
    content = {type = "empty-widget", style_mods = {width = 1000, height = 700}}
  }
end

function stations_tab.init()
end

function stations_tab.refresh(refs, state)
end

return stations_tab

