local gui = require("__flib__.gui3")

local util = require("scripts.util")

-- local titlebar = require("scripts.gui.main.components.titlebar")
-- local toolbar = require("scripts.gui.main.components.toolbar")

-- local tabs = {}
-- for _, tab_name in ipairs{"depots", "stations", "inventory", "history", "alerts"} do
--   tabs[tab_name] = require("scripts.gui.main.components."..tab_name..".tab")
-- end

local root = gui.root("main")

function root.init()
  return {
    base = {
      active_tab = "depots",
      auto_refresh = false,
      pinned = false,
      pinning = false,
      visible = false
    },
    -- search = toolbar.init(),
    -- depots = tabs.depots.init()
  }
end

function root.setup(refs)
  refs.titlebar_flow.drag_target = refs.window
  refs.window.force_auto_center()
end

function root.update(state, msg, e)
  -- local tab = msg.tab
  -- local comp = msg.comp
  -- local action = msg.action

  -- if tab == "base" then
  --   if comp == "base" then
  --     local player, _, state, refs = util.get_updater_properties(e.player_index)

  --     if action == "open" then
  --       local base_window = refs.base.window

  --       base_window.visible = true
  --       -- TODO bring to front

  --       state.base.visible = true
  --       player.set_shortcut_toggled("ltnm-toggle-gui", true)

  --       if not state.base.pinned then
  --         player.opened = base_window
  --       end
  --     elseif action == "close" then
  --       -- don't actually close if we just pinned the GUI
  --       if state.base.pinning then return end

  --       local base_window = refs.base.window

  --       base_window.visible = false

  --       state.base.visible = false
  --       player.set_shortcut_toggled("ltnm-toggle-gui", false)

  --       if player.opened == base_window then
  --         player.opened = nil
  --       end
  --     end
  --   elseif comp == "titlebar" then
  --     titlebar.update(msg, e)
  --   elseif comp == "toolbar" then
  --     toolbar.update(msg, e)
  --   end
  -- elseif tab == "depots" then
  --   tabs.depots.update(msg, e)
  -- end
end

function root.view(state)
  return (
    {
      type = "frame",
      direction = "vertical",
      visible = state.base.visible,
      on_closed = {comp = "base", action = "close"},
      ref = "window",
      children = {
        -- titlebar.view(),
        {
          type = "frame",
          style = "inside_deep_frame",
          direction = "vertical",
          children = {
            -- toolbar.view(),
            {
              type = "tabbed-pane",
              style = "tabbed_pane_with_no_side_padding",
              ref = {"base", "tabbed_pane"},
              children = {
                -- tabs.depots.view(player_table.translations.gui.locale_identifier),
                -- tabs.stations.view(),
                -- tabs.inventory.view(),
                -- tabs.history.view(),
                -- tabs.alerts.view(),
              }
            }
          }
        }
      }
    }
  )
end

return root