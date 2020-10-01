local gui = require("__flib__.gui-new")

local titlebar = require("scripts.gui.main.components.titlebar")
local toolbar = require("scripts.gui.main.components.toolbar")

local tabs = {}
for _, tab_name in ipairs{"depots", "stations", "inventory", "history", "alerts"} do
  tabs[tab_name] = require("scripts.gui.main.components."..tab_name..".tab")
end

local component = require("lib.gui-component")()

-- gui.add_handlers{
--   main = {
--     base = {
--       titlebar = titlebar.handlers,
--       window = {
--         on_gui_closed = function(e)
--           local player_table = global.players[e.player_index]
--           if player_table.flags.gui_open then
--             main_gui.close(game.get_player(e.player_index), player_table)
--           end
--         end
--       }
--     }
--   }
-- }

function component.init()
  return {
    pinned = false
  }
end

function component.update(msg, e)

end

function component.build()
  return (
    {
      type = "frame",
      direction = "vertical",
      visible = false,
      on_closed = {comp = "base", action = "close"},
      ref = {"base", "window"},
      children = {
        titlebar(),
        {
          type = "frame",
          style = "inside_deep_frame",
          direction = "vertical",
          children = {
            toolbar(),
            {
              type = "tabbed-pane",
              style = "tabbed_pane_with_no_side_padding",
              ref = {"base", "tabbed_pane"},
              children = {
                -- tabs.depots(),
                tabs.stations(),
                tabs.inventory(),
                tabs.history(),
                tabs.alerts(),
              }
            }
          }
        }
      }
    }
  )
end

return component