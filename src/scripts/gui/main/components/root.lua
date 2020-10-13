local gui = require("__flib__.gui3")

local constants = require("constants")

local titlebar = require("scripts.gui.main.components.base.titlebar")
local toolbar = require("scripts.gui.main.components.base.toolbar")

local tab_names = {"depots", "stations", "inventory", "history", "alerts"}
local tabs = {}
for _, tab_name in ipairs(tab_names) do
  tabs[tab_name] = require("scripts.gui.main.components."..tab_name..".tab")
end

local root = gui.root("main")

function root.init(player_index)
  local player_table = global.players[player_index]
  return {
    base = {
      selected_tab = "depots",
      auto_refresh = false,
      pinned = false,
      pinning = false,
      visible = false
    },
    search = toolbar.init(),
    depots = tabs.depots.init(),
    stations = tabs.stations.init(),
    -- LTN data
    ltn_data = global.data,
    -- meta
    constants = constants.gui[player_table.translations.gui.locale_identifier],
    translations = player_table.translations,
    player_index = player_index
  }
end

function root.setup(refs)
  refs.titlebar_flow.drag_target = refs.window
  refs.window.force_auto_center()
end

function root.update(state, msg, e, refs)
  if msg.update_ltn_data then
    state.ltn_data = global.data
  end

  if msg.comp == "base" then
    local player = game.get_player(e.player_index)

    if msg.action == "open" then
      state.base.visible = true
      player.set_shortcut_toggled("ltnm-toggle-gui", true)

      refs.window.bring_to_front()

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
    elseif msg.action == "update_selected_tab" then
      state.base.selected_tab = tab_names[e.element.selected_tab_index]
    end
  elseif msg.comp == "titlebar" then
    titlebar.update(state, msg, e, refs)
  elseif msg.comp == "toolbar" then
    toolbar.update(state, msg, e)
  else
    tabs[state.base.selected_tab].update(state, msg, e, refs)
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
        titlebar(state),
        {
          type = "frame",
          style = "inside_deep_frame",
          direction = "vertical",
          children = {
            toolbar(state),
            {
              type = "tabbed-pane",
              style = "ltnm_tabbed_pane",
              on_selected_tab_changed = {comp = "base", action = "update_selected_tab"},
              tabs = {
                tabs.depots(state),
                tabs.stations(state),
                tabs.inventory(state),
                tabs.history(state),
                tabs.alerts(state),
              }
            }
          }
        }
      }
    }
  )
end

return root