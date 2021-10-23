local inventory_tab = {}

function inventory_tab.build()
  return {
    tab = {type = "tab", caption = {"gui.ltnm-inventory"}, enabled = false, ref = {"inventory", "tab"}},
    content = {type = "empty-widget", style_mods = {width = 1000, height = 700}}
  }
end

function inventory_tab.init()
end

function inventory_tab.refresh(refs, state)
end

return inventory_tab


