local alerts_tab = {}

function alerts_tab.build()
  return {
    tab = {type = "tab", caption = {"gui.ltnm-alerts"}, enabled = false, ref = {"alerts", "tab"}},
    content = {type = "empty-widget", style_mods = {width = 1000, height = 700}}
  }
end

function alerts_tab.init()
end

function alerts_tab.refresh(refs, state)
end

return alerts_tab


