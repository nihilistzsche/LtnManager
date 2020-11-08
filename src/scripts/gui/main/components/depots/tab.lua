local gui = require("__flib__.gui-beta")

local depot_select = require("scripts.gui.main.components.depots.depot-select")
local trains_list = require("scripts.gui.main.components.depots.trains-list")

local component = {}

function component.build(widths)
  return (
    {
      tab = {type = "tab", caption = {"ltnm-gui.depots"}},
      content = (
        {type = "flow", style = "ltnm_tab_horizontal_flow", children = {
          depot_select.build(widths),
          trains_list.build(widths)
        }}
      )
    }
  )
end

function component.init()
  -- TODO split this up?
  return trains_list.init()
end

function component.update(player, player_table, state, refs)
  depot_select.update(player, player_table, state, refs)
  trains_list.update(player, player_table, state, refs)
end

return component