local main_gui = {}

local gui = require("__flib__.gui")

gui.add_handlers{
  main = {
    base = {
      titlebar = {
        close_button = {
          on_gui_click = function(e)
            main_gui.close(game.get_player(e.player_index), global.players[e.player_index])
          end
        }
      },
      window = {
        on_gui_closed = function(e)
          local player_table = global.players[e.player_index]
          -- this flag will be set if we used the close button to close this GUI
          if not player_table.flags.closing_gui then
            main_gui.close(game.get_player(e.player_index), player_table)
          end
        end
      }
    }
  }
}

local function frame_action_button(sprite, handlers, save_as, tooltip)
  return {
    type = "sprite-button",
    style = "frame_action_button",
    sprite = sprite.."_white",
    hovered_sprite = sprite.."_black",
    clicked_sprite = sprite.."_black",
    tooltip = tooltip,
    handlers = handlers,
    save_as = save_as
  }
end

local placeholder = {type = "empty-widget", style_mods = {width = 500, height = 350}}

function main_gui.create(player, player_table)
  local base_elems = gui.build(player.gui.screen, {
    {
      type = "frame",
      direction = "vertical",
      elem_mods = {visible = false},
      handlers = "main.base.window",
      save_as = "window",
      children = {
        {type = "flow", save_as = "titlebar_flow", children = {
          {type = "label", style = "frame_title", caption = {"mod-name.LtnManager"}, ignored_by_interaction = true},
          {type = "empty-widget", style = "flib_titlebar_drag_handle", ignored_by_interaction = true},
          frame_action_button("ltnm_pin", nil, nil, {"ltnm-gui.keep-open"}),
          frame_action_button("ltnm_refresh", nil, nil, {"ltnm-gui.refresh"}),
          frame_action_button("utility/close", "main.base.titlebar.close_button")
        }},
        {
          type = "frame",
          style = "inside_deep_frame",
          direction = "vertical",
          children = {
            -- main toolbar
            {type = "frame", style = "subheader_frame", style_mods = {bottom_margin = 12}, children = {
              {type = "empty-widget", style = "flib_horizontal_pusher"},
              {type = "sprite-button", style = "tool_button"}
            }},
            -- tabbed pane
            {
              type = "tabbed-pane",
              style = "tabbed_pane_with_no_side_padding",
              save_as = "tabbed_pane.root",
              children = {
                {type = "tab-and-content", tab = {type = "tab", caption = {"ltnm-gui.depots"}}, content = placeholder},
                {
                  type = "tab-and-content",
                  tab = {type = "tab", caption = {"ltnm-gui.stations"}},
                  content = placeholder
                },
                {
                  type = "tab-and-content",
                  tab = {type = "tab", caption = {"ltnm-gui.inventory"}},
                  content = placeholder
                },
                {type = "tab-and-content", tab = {type = "tab", caption = {"ltnm-gui.history"}}, content = placeholder},
                {type = "tab-and-content", tab = {type = "tab", caption = {"ltnm-gui.alerts"}}, content = placeholder},
              }
            }
          }
        }
      }
    }
  })

  -- dragging and centering
  base_elems.titlebar_flow.drag_target = base_elems.window
  base_elems.window.force_auto_center()

  -- save to player table
  player_table.gui.main = {
    base = base_elems,
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
    player_table.flags.closing_gui = true
    player.opened = nil
    player_table.flags.closing_gui = false
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