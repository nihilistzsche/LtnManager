local history_tab = {}

function history_tab.build()
  return {
    tab = {type = "tab", caption = {"gui.ltnm-history"}, enabled = false, ref = {"history", "tab"}},
    content = {type = "empty-widget", style_mods = {width = 1000, height = 700}}
  }
end

function history_tab.init()
end

function history_tab.refresh(refs, state)
end

return history_tab


