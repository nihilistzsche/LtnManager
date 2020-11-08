local gui = require("__flib__.gui-beta")

local constants = require("constants")

local util = require("scripts.util")

local function frame_action_button(sprite, tooltip, on_click)
  return {
    type = "sprite-button",
    style = "frame_action_button",
    sprite = sprite.."_white",
    hovered_sprite = sprite.."_black",
    clicked_sprite = sprite.."_black",
    tooltip = tooltip,
    mouse_button_filter = {"left"},
    handlers = {
      on_click = on_click
    }
  }
end

local component = {}

function component.build()
  return (
    {type = "flow", ref = {"base", "titlebar_flow"}, children = {
      {type = "label", style = "frame_title", caption = {"mod-name.LtnManager"}, ignored_by_interaction = true},
      {type = "empty-widget", style = "flib_titlebar_drag_handle", ignored_by_interaction = true},
      {
        type = "label",
        style = "bold_label",
        style_mods = {
          font_color = constants.colors.red.tbl,
          top_margin = 1,
          right_margin = 8,
        },
        caption = {"ltnm-gui.dispatcher-not-enabled"},
        tooltip = {"ltnm-gui.dispatcher-not-enabled-tooltip"},
        elem_mods = {
          visible = false
        }
      },
      frame_action_button(
        "ltnm_pin",
        {"ltnm-gui.keep-open"},
        "main_toggle_pinned"
      ),
      frame_action_button(
        "ltnm_refresh",
        {"ltnm-gui.refresh"},
        "main_handle_refresh_click"
      ),
      frame_action_button("utility/close", nil, "main_close")
    }}
  )
end

-- HANDLERS

local function toggle_pinned(e)
  local player, _, state, refs = util.get_gui_data(e.player_index)

  if state.base.pinned then
    state.base.pinned = false
    e.element.style = "frame_action_button"
    e.element.sprite = "ltnm_pin_white"
    player.opened = refs.base.window
    refs.base.window.force_auto_center()
  else
    state.base.pinned = true
    e.element.style = "flib_selected_frame_action_button"
    e.element.sprite = "ltnm_pin_black"

    -- set "pinning" flag to prevent actually closing the GUI
    state.base.pinning = true
    player.opened = nil
    state.base.pinning = false

    refs.base.window.auto_center = false
  end
end

local function handle_refresh_click(e)
  if e.shift then
    local _, _, state, _ = util.get_gui_data(e.player_index)

    if state.base.auto_refresh then
      state.base.auto_refresh = false
      e.element.style = "frame_action_button"
      e.element.sprite = "ltnm_refresh_white"
    else
      state.base.auto_refresh = true
      e.element.style = "flib_selected_frame_action_button"
      e.element.sprite = "ltnm_refresh_black"
    end
  else
    -- TODO
  end
end

gui.add_handlers{
  main_toggle_pinned = toggle_pinned,
  main_handle_refresh_click = handle_refresh_click
}

return component