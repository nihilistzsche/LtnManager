local gui = require("__flib__.gui-beta")

local util = require("scripts.util")

local search_bar = require("scripts.gui.main.components.base.search-bar")
local titlebar = require("scripts.gui.main.components.base.titlebar")

local tab_names = {"depots"}
local tabs = {}
for _, tab_name in ipairs(tab_names) do
  tabs[tab_name] = require("scripts.gui.main.components."..tab_name..".tab")
end

local component = {}

function component.build(widths)
  return (
    {
      type = "frame",
      direction = "vertical",
      elem_mods = {visible = false},
      handlers = {
        on_closed = "main_close"
      },
      ref = {"base", "window"},
      children = {
        titlebar.build(),
        {
          type = "frame",
          style = "inside_deep_frame",
          direction = "vertical",
          children = {
            search_bar.build(),
            {
              type = "tabbed-pane",
              style = "ltnm_tabbed_pane",
              handlers = {
                on_selected_tab_changed = "main_change_selected_tab",
              },
              tabs = {
                tabs.depots.build(widths),
                -- tabs.stations(state),
                -- tabs.inventory(state),
                -- tabs.history(state),
                -- tabs.alerts(state),
              }
            }
          }
        }
      }
    }
  )
end

function component.setup(refs, ltn_data)
  refs.base.titlebar_flow.drag_target = refs.base.window
  refs.base.window.force_auto_center()

  search_bar.setup(refs, ltn_data)
end

function component.init()
  return {
    base = {
      selected_tab = "depots",
      auto_refresh = false,
      pinned = false,
      pinning = false,
      visible = false
    },
    search = search_bar.init(),
    depots = tabs.depots.init(),
    -- stations = tabs.stations.init(),
    -- history = tabs.history.init(),
    -- LTN data
    ltn_data = global.data
  }
end

function component.open(e)
  local player, _, state, refs = util.get_gui_data(e.player_index)

  state.base.visible = true
  refs.base.window.visible = true

  player.set_shortcut_toggled("ltnm-toggle-gui", true)

  if not state.base.pinned then
    player.opened = refs.base.window
  end
end

-- both called directly and used as an element handler
function component.close(e)
  local player, _, state, refs = util.get_gui_data(e.player_index)

  -- don't actually close if we just pinned the GUI
  if state.base.pinning then return end

  state.base.visible = false
  refs.base.window.visible = false

  player.set_shortcut_toggled("ltnm-toggle-gui", false)

  if player.opened == refs.base.window then
    player.opened = nil
  end
end

function component.update(player, player_table, state, refs)
  -- update active tab
  tabs[state.base.selected_tab].update(player, player_table, state, refs)
end

gui.add_handlers{
  main_close = component.close
}

return component