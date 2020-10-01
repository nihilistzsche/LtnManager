local gui = require("__flib__.gui-new")

local titlebar = require("scripts.gui.main.components.titlebar")
local toolbar = require("scripts.gui.main.components.toolbar")

local tabs = {}
for _, tab_name in ipairs{"depots", "stations", "inventory", "history", "alerts"} do
  tabs[tab_name] = require("scripts.gui.main.components."..tab_name..".tab")
end

local main_gui = {}

function main_gui.update(msg, e)
  local player = game.get_player(e.player_index)
  local player_table = global.players[e.player_index]
  local gui_data = player_table.gui.main
  local state = gui_data.state
  local refs = gui_data.refs

  local tab = msg.tab
  local comp = msg.comp
  local action = msg.action

  if tab == "base" then
    if comp == "base" then
      if action == "open" then
        local base_window = refs.base.window

        base_window.visible = true
        -- TODO bring to front

        state.base.visible = true
        player.set_shortcut_toggled("ltnm-toggle-gui", true)

        if not gui_data.state.base.pinned then
          player.opened = base_window
        end
      elseif action == "close" then
        -- don't actually close if we just pinned the GUI
        if state.base.pinning then return end

        local base_window = refs.base.window

        base_window.visible = false

        state.base.visible = false
        player.set_shortcut_toggled("ltnm-toggle-gui", false)

        if player.opened == base_window then
          player.opened = nil
        end
      end
    elseif comp == "titlebar" then
      titlebar.update(player, state, refs, action, e)
    end
  elseif tab == "depots" then
    tabs.depots.update(player, player_table, state, refs, msg)
  end
end

gui.updaters.main = main_gui.update

function main_gui.create(player, player_table)
  -- create GUI from template
  local refs, handlers = gui.build(player.gui.screen, "main", {
    {
      type = "frame",
      direction = "vertical",
      visible = false,
      on_closed = {tab = "base", comp = "base", action = "close"},
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
                tabs.depots(),
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
  })

  -- dragging and centering
  refs.base.titlebar.flow.drag_target = refs.base.window
  refs.base.window.force_auto_center()

  -- save to player table
  player_table.gui.main = {
    handlers = handlers,
    refs = refs,
    state = {
      base = {
        auto_refresh = false,
        pinned = false,
        pinning = false,
        visible = false
      },
      search = {
        network_id = -1,
        query = "",
        surface = -1
      }
    }
  }

  -- set flag and shortcut state
  player_table.flags.can_open_gui = true
  player.set_shortcut_available("ltnm-toggle-gui", true)
end

function main_gui.destroy(player, player_table)
  -- deregister all handlers
  gui.update_filters("main", player.index, nil, "remove")

  -- destroy window
  player_table.gui.main.base.window.destroy()

  -- remove from player table
  player_table.gui.main = nil

  -- set flag and shortcut state
  player_table.flags.can_open_gui = false
  player.set_shortcut_available("ltnm-toggle-gui", false)
end

function main_gui.toggle(player_index, player_table)
  local action = player_table.gui.main.state.base.visible and "close" or "open"
  main_gui.update({tab = "base", comp = "base", action = action}, {player_index = player_index})
end

function main_gui.update_active_tab(player_index, player_table)
  local active_tab = player_table.gui.main.state.base.active_tab
  main_gui.update({tab = active_tab, update = true}, {player_index = player_index})
end

return main_gui