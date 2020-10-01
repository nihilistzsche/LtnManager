local gui = require("__flib__.gui-new")

local base = require("scripts.gui.main.components.base")

local main_gui = {}

function main_gui.create(player, player_table)
  -- create GUI from template
  local refs, assigned_handlers = gui.build(player.gui.screen, "main", {base()})

  -- dragging and centering
  refs.base.titlebar.flow.drag_target = refs.base.window
  refs.base.window.force_auto_center()

  -- save to player table
  player_table.gui.main = {
    assigned_handlers = assigned_handlers,
    refs = refs,
    state = base.init()
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
  local base_window = gui_data.refs.base.window

  -- show window
  base_window.visible = true
  -- TODO bring to front

  -- set flag and shortcut state
  player_table.flags.gui_open = true
  player.set_shortcut_toggled("ltnm-toggle-gui", true)

  -- set as opened
  if not gui_data.state.pinned then
    player.opened = base_window
  end
end

function main_gui.close(player, player_table)
  local gui_data = player_table.gui.main
  local base_window = gui_data.refs.base.window

  -- hide window
  base_window.visible = false

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

function main_gui.update(msg, e)
  base.update(msg, e)
end

gui.updaters.main = main_gui.update

return main_gui