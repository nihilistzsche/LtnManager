local main_gui = {}

local gui = require("__flib__.gui")

local titlebar = require("scripts.gui.main.titlebar")
local toolbar = require("scripts.gui.main.toolbar")

local tabs = {}
for _, tab_name in ipairs{"depots", "stations", "inventory", "history", "alerts"} do
  tabs[tab_name] = require("scripts.gui.main."..tab_name..".tab")
end

gui.add_handlers{
  main = {
    base = {
      titlebar = titlebar.handlers,
      window = {
        on_gui_closed = function(e)
          local player_table = global.players[e.player_index]
          if player_table.flags.gui_open then
            main_gui.close(game.get_player(e.player_index), player_table)
          end
        end
      }
    }
  }
}

local template = {
  {
    type = "frame",
    direction = "vertical",
    elem_mods = {visible = false},
    handlers_prefix = "main.base.",
    handlers = "window",
    save_as_prefix = "base.",
    save_as = "window",
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
            reset_handlers_prefix = true,
            handlers_prefix = "main.",
            save_as = "tabbed_pane.root",
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
}

function main_gui.create(player, player_table)
  -- create GUI from template
  local elems = gui.build(player.gui.screen, template)

  -- dragging and centering
  elems.base.titlebar.flow.drag_target = elems.base.window
  elems.base.window.force_auto_center()

  -- save to player table
  player_table.gui.main = {
    base = elems.base,
    flags = {
      pinned = false
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

function main_gui.open(player, player_table)
  local gui_data = player_table.gui.main
  local base_window = gui_data.base.window

  -- show window
  base_window.visible = true
  -- TODO bring to front

  -- set flag and shortcut state
  player_table.flags.gui_open = true
  player.set_shortcut_toggled("ltnm-toggle-gui", true)

  -- set as opened
  if not gui_data.flags.pinned then
    player.opened = base_window
  end
end

function main_gui.close(player, player_table)
  local gui_data = player_table.gui.main
  local base_window = gui_data.base.window

  -- hide window
  player_table.gui.main.base.window.visible = false

  -- set flag and shortcut state
  player_table.flags.gui_open = false
  player.set_shortcut_toggled("ltnm-toggle-gui", false)

  -- unset as opened
  if player.opened == base_window then
    player.opened = nil
  end
end

function main_gui.toggle(player, player_table)
  if player_table.flags.gui_open then
    main_gui.close(player, player_table)
  else
    main_gui.open(player, player_table)
  end
end

return main_gui