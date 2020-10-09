local gui = require("__flib__.gui3")

local titlebar = require("scripts.gui.main.components.titlebar")
-- local toolbar = require("scripts.gui.main.components.toolbar")

local tabs = {}
for _, tab_name in ipairs{"depots", "stations", "inventory", "history", "alerts"} do
  tabs[tab_name] = require("scripts.gui.main.components."..tab_name..".tab")
end

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

function root.update(state, msg, e, refs)
  if msg.comp == "base" then
    local player = game.get_player(e.player_index)

    if msg.action == "open" then
      state.base.visible = true
      player.set_shortcut_toggled("ltnm-toggle-gui", true)

      if not state.base.pinned then
        player.opened = refs.window
      end
    elseif msg.action == "close" then
      -- don't actually close if we just pinned the GUI
      if state.base.pinning then return end

      state.base.visible = false
      player.set_shortcut_toggled("ltnm-toggle-gui", false)

      if player.opened == refs.window then
        player.opened = nil
      end
    end
  elseif msg.comp == "titlebar" then
    titlebar.update(state, msg, e, refs)
  elseif msg.comp == "toolbar" then
    -- toolbar.update(msg, e)
  end
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
        titlebar.view(state),
        {
          type = "frame",
          style = "inside_deep_frame",
          direction = "vertical",
          children = {
            -- toolbar.view(),
            {
              type = "tabbed-pane",
              style = "tabbed_pane_with_no_side_padding",
              tabs = {
                tabs.depots.view(state),
                tabs.stations.view(),
                tabs.inventory.view(),
                tabs.history.view(),
                tabs.alerts.view(),
              }
            }
          }
        }
      }
    }
  )
end

return root