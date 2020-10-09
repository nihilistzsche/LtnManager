-- local depot_select = require("scripts.gui.main.components.depots.depot-select")
-- local trains_list = require("scripts.gui.main.components.depots.trains-list")

local component = {}

function component.init()
  -- return trains_list.init()
end

function component.update(state, msg, e)
  -- if msg.update then
  --   depot_select.update(state, msg, e)
  --   trains_list.update(state, msg, e)
  -- elseif msg.comp == "depot_select" then
  --   depot_select.update(state, msg, e)
  -- elseif msg.comp == "trains_list" then
  --   trains_list.update(state, msg, e)
  -- end
end

function component.view(state)
  return (
    {
      type = "tab-and-content",
      tab = {type = "tab", caption = {"ltnm-gui.depots"}},
      content = (
        {type = "flow", style = "ltnm_tab_horizontal_flow", children = {
          -- depot_select.view(state),
          -- trains_list.view(state)
        }}
      )
    }
  )
end

return component