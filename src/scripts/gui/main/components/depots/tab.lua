local component = require("lib.gui-component")()

local depot_select = require("scripts.gui.main.components.depots.depot-select")
local trains_list = require("scripts.gui.main.components.depots.trains-list")

function component.get_default_state()
  return {}
end

function component.get_refs_outline()
  return {
    depot_select = {
      buttons = {}
    },
    trains_list = {
      rows = {}
    }
  }
end

function component.get_handlers_outline()
  return {
    depot_buttons = {},
    train_rows = {}
  }
end

function component.update(player, player_table, state, refs, handlers, msg, e)
  if msg.update then
    depot_select.update(player, player_table, state, refs, handlers, msg, e)
    trains_list.update(player, player_table, state, refs, msg, e)
  elseif msg.comp == "depot_select" then
    depot_select.update(player, player_table, state, refs, handlers, msg, e)
  elseif msg.comp == "trains_list" then
    trains_list.update(player, player_table, state, refs, handlers, msg, e)
  end
end

function component.build()
  return (
    {
      type = "tab-and-content",
      tab = {type = "tab", caption = {"ltnm-gui.depots"}},
      content = (
        {type = "flow", style = "ltnm_tab_horizontal_flow", children = {
          depot_select(),
          trains_list()
        }}
      )
    }
  )
end

return component