local component = require("lib.gui-component")()

local depot_select = require("scripts.gui.main.components.depots.depot-select")
local trains_list = require("scripts.gui.main.components.depots.trains-list")

function component.get_default_state()
  return trains_list.get_default_state()
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

function component.update(msg, e)
  if msg.update then
    depot_select.update(msg, e)
    trains_list.update(msg, e)
  elseif msg.comp == "depot_select" then
    depot_select.update(msg, e)
  elseif msg.comp == "trains_list" then
    trains_list.update(msg, e)
  end
end

function component.build(player_locale)
  return (
    {
      type = "tab-and-content",
      tab = {type = "tab", caption = {"ltnm-gui.depots"}},
      content = (
        {type = "flow", style = "ltnm_tab_horizontal_flow", children = {
          depot_select(),
          trains_list(player_locale)
        }}
      )
    }
  )
end

return component