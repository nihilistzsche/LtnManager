local gui = require("__flib__.gui-beta")

local main_gui = {}

function main_gui.build(player, player_table)
  local refs = gui.build(player.gui.screen, {
    {
      type = "frame",
      direction = "vertical",
      visible = false,
      ref = {"window"},
      actions = {
        on_closed = {gui = "main", action = "close"}
      },
      children = {
        -- titlebar
        {type = "flow", style = "flib_titlebar_flow", ref = {"titlebar", "flow"}, children = {
          {type = "label", style = "frame_title", caption = {"mod-name.LtnManager"}, ignored_by_interaction = true},
          {type = "empty-widget", style = "flib_titlebar_drag_handle", ignored_by_interaction = true},
          {
            type = "sprite-button",
            style = "frame_action_button",
            sprite = "ltnm_pin_white",
            hovered_sprite = "ltnm_pin_black",
            clicked_sprite = "ltnm_pin_black",
            mouse_button_filter = {"left"},
            tooltip = {"gui.ltnm-keep-open"},
            ref = {"titlebar", "pin_button"},
            actions = {
              on_click = {gui = "main", action = "toggle_pinned"}
            }
          },
          {
            type = "sprite-button",
            style = "frame_action_button",
            sprite = "ltnm_refresh_white",
            hovered_sprite = "ltnm_refresh_black",
            clicked_sprite = "ltnm_refresh_black",
            tooltip = {"gui.ltnm-refresh-tooltip"},
            mouse_button_filter = {"left"},
            ref = {"titlebar", "refresh_button"},
            actions = {
              on_click = {gui = "main", transform = "handle_refresh_click"}
            }
          },
          {
            type = "sprite-button",
            style = "frame_action_button",
            sprite = "utility/close_white",
            hovered_sprite = "utility/close_black",
            clicked_sprite = "utility/close_black",
            mouse_button_filter = {"left"},
            actions = {
              on_click = {gui = "main", action = "close"}
            }
          }
        }},
        {type = "frame", style = "inside_deep_frame", direction = "vertical", children = {
          -- search bar
          {type = "frame", style = "subheader_frame", style_mods = {bottom_margin = 12}, children = {
            -- text search
            {type = "label", style = "subheader_caption_label", caption = {"gui.ltnm-search-label"}},
            {
              type = "textfield",
              style_mods = {left_margin = 8},
              clear_and_focus_on_right_click = true,
              ref = {"toolbar", "text_search_field"},
              actions = {
                on_text_changed = {gui = "main", action = "update_text_search_query"}
              }
            },
            {type = "empty-widget", style = "flib_horizontal_pusher"},
            {type = "label", style = "caption_label", caption = {"gui.ltnm-network-id-label"}},
            {
              type = "textfield",
              style_mods = {left_margin = 8, width = 120},
              numeric = true,
              allow_negative = true,
              clear_and_focus_on_right_click = true,
              text = "-1",
              ref = {"toolbar", "network_id_field"},
              actions = {
                on_text_changed = {gui = "main", action = "update_network_id_query"}
              }
            }
            -- TODO: maybe surface dropdown?
          }},
          -- tabbed pane
          {type = "tabbed-pane", tabs = {
            {
              tab = {type = "tab", caption = {"gui.ltnm-trains"}, ref = {"trains", "tab"}},
              content = {type = "empty-widget", style_mods = {width = 1000, height = 700}}
            },
            {
              tab = {type = "tab", caption = {"gui.ltnm-stations"}, enabled = false, ref = {"stations", "tab"}},
              content = {type = "empty-widget", style_mods = {width = 1000, height = 700}}
            },
            {
              tab = {type = "tab", caption = {"gui.ltnm-inventory"}, enabled = false, ref = {"inventory", "tab"}},
              content = {type = "empty-widget", style_mods = {width = 1000, height = 700}}
            },
            {
              tab = {type = "tab", caption = {"gui.ltnm-history"}, enabled = false, ref = {"history", "tab"}},
              content = {type = "empty-widget", style_mods = {width = 1000, height = 700}}
            },
            {
              tab = {type = "tab", caption = {"gui.ltnm-alerts"}, enabled = false, ref = {"alerts", "tab"}},
              content = {type = "empty-widget", style_mods = {width = 1000, height = 700}}
            }
          }}
        }}
      }
    }
  })

  -- dragging and centering
  refs.titlebar.flow.drag_target = refs.window
  refs.window.force_auto_center()

  -- save to player table
  player_table.guis.main = {
    refs = refs,
    state = {
      auto_refresh = false,
      network_id_query = -1,
      pinned = false,
      pinning = false,
      search_query = "",
      visible = false
    }
  }

  -- update flag and shortcut button
  player_table.flags.can_open_gui = true
  player.set_shortcut_available("ltnm-toggle-gui", true)
end

function main_gui.destroy(player_table)
  -- TODO: nil check
  player_table.guis.main.refs.window.destroy()
  player_table.guis.main = nil

  -- set flag and shortcut button
  player_table.flags.can_open_gui = false
  player.set_shortcut_available("ltnm-toggle-gui", false)
end

function main_gui.open(player, player_table)
  local gui_data = player_table.guis.main
  -- TODO:
  if not gui_data or not gui_data.refs.window.valid then error("Handle GUI not existing!") end

  gui_data.refs.window.bring_to_front()
  gui_data.refs.window.visible = true
  gui_data.state.visible = true

  if not gui_data.state.pinned then
    player.opened = gui_data.refs.window
  end

  player.set_shortcut_toggled("ltnm-toggle-gui", true)
end

function main_gui.close(player, player_table)
  local gui_data = player_table.guis.main
  if gui_data.state.pinning then return end

  gui_data.refs.window.visible = false
  gui_data.state.visible = false

  if player.opened == gui_data.refs.window then
    player.opened = nil
  end

  player.set_shortcut_toggled("ltnm-toggle-gui", false)
end

function main_gui.toggle(player, player_table)
  local gui_data = player_table.guis.main
  -- TODO: nil check

  if gui_data.state.visible then
    main_gui.close(player, player_table)
  else
    main_gui.open(player, player_table)
  end
end

function main_gui.handle_action(e, msg)
  local player = game.get_player(e.player_index)
  local player_table = global.players[e.player_index]
  local gui_data = player_table.guis.main
  local refs = gui_data.refs
  local state = gui_data.state

  -- transforms
  if msg.transform == "handle_refresh_click" then
    if e.shift then
      msg.action = "toggle_auto_refresh"
    else
      msg.refresh = true
    end
  end

  -- actions
  if msg.action == "close" then
    main_gui.close(player, player_table)
  elseif msg.action == "toggle_auto_refresh" then
    state.auto_refresh = not state.auto_refresh
    local refresh_button = refs.titlebar.refresh_button
    refresh_button.style = state.auto_refresh and "flib_selected_frame_action_button" or "frame_action_button"
    refresh_button.sprite = state.auto_refresh and "ltnm_refresh_black" or "ltnm_refresh_white"
  elseif msg.action == "toggle_pinned" then
    state.pinned = not state.pinned
    local pin_button = refs.titlebar.pin_button
    pin_button.style = state.pinned and "flib_selected_frame_action_button" or "frame_action_button"
    pin_button.sprite = state.pinned and "ltnm_pin_black" or "ltnm_pin_white"

    if state.pinned then
      state.pinning = true
      player.opened = nil
      state.pinning = false
    else
      player.opened = refs.window
      refs.window.force_auto_center()
    end
  elseif msg.action == "update_text_search_query" then
    state.text_search_query = refs.toolbar.text_search_field.text
    msg.refresh = true
  elseif msg.action == "update_network_id_query" then
    state.network_id_query = tonumber(refs.toolbar.network_id_field.text) or -1
    msg.refresh = true
  end

  if msg.refresh then
    -- TODO:
  end
end

return main_gui
