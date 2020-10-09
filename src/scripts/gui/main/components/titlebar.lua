local gui = require("__flib__.gui3")

-- local util = require("scripts.util")

local component = {}

function component.update(state, msg, e, refs)
  if msg.action == "toggle_pinned" then
    local pinned = state.base.pinned

    if pinned then
      state.base.pinned = false

      player.opened = refs.base.window
      refs.base.window.force_auto_center()
    else
      state.base.pinned = true

      -- a `pinning` flag is needed so the GUI doesn't close when we pin it
      state.base.pinning = true
      player.opened = nil
      state.base.pinning = false

      refs.base.window.auto_center = false
    end
  end
end

local function frame_action_button(sprite, tooltip, on_click, enabled)
  return {
    type = "sprite-button",
    style = enabled and "flib_selected_frame_action_button"  or "frame_action_button",
    sprite = sprite..(enabled and "_black" or "_white"),
    hovered_sprite = sprite.."_black",
    clicked_sprite = sprite.."_black",
    tooltip = tooltip,
    on_click = on_click
  }
end

function component.view(state)
  return (
    {type = "flow", ref = {"base", "titlebar", "flow"}, children = {
      {type = "label", style = "frame_title", caption = {"mod-name.LtnManager"}, ignored_by_interaction = true},
      {type = "empty-widget", style = "flib_titlebar_drag_handle", ignored_by_interaction = true},
      frame_action_button(
        "ltnm_pin",
        {"ltnm-gui.keep-open"},
        {tab = "base", comp = "titlebar", action = "toggle_pinned"},
        {"base", "titlebar", "pin_button"}
      ),
      -- frame_action_button(
      --   "ltnm_refresh",
      --   {"ltnm-gui.refresh"},
      --   {tab = "base", comp = "titlebar", action = "handle_refresh_click"},
      --   {"base", "titlebar", "refresh_button"}
      -- ),
      frame_action_button("utility/close", nil, {tab = "base", comp = "base", action = "close"})
    }}
  )
end

return component