local component = require("lib.gui-component")()

function component.update(player, state, refs, action)
  if action == "toggle_pinned" then
    local pinned = state.base.pinned
    local pin_button = refs.base.titlebar.pin_button

    if pinned then
      pin_button.style = "frame_action_button"
      state.base.pinned = false

      player.opened = refs.base.window
      refs.base.window.force_auto_center()
    else
      pin_button.style = "flib_selected_frame_action_button"
      state.base.pinned = true

      -- a `pinning` flag is needed so the GUI doesn't close when we pin it
      state.base.pinning = true
      player.opened = nil
      state.base.pinning = false
    end
  end
end

local function frame_action_button(sprite, tooltip, on_click, ref)
  return {
    type = "sprite-button",
    style = "frame_action_button",
    sprite = sprite.."_white",
    hovered_sprite = sprite.."_black",
    clicked_sprite = sprite.."_black",
    tooltip = tooltip,
    on_click = on_click,
    ref = ref
  }
end

function component.build()
  return (
    {type = "flow", ref = {"base", "titlebar", "flow"}, children = {
      {type = "label", style = "frame_title", caption = {"mod-name.LtnManager"}, ignored_by_interaction = true},
      {type = "empty-widget", style = "flib_titlebar_drag_handle", ignored_by_interaction = true},
      frame_action_button(
        "ltnm_pin",
        {"ltnm-gui.keep-open"},
        {comp = "titlebar", action = "toggle_pinned"},
        {"base", "titlebar", "pin_button"}
      ),
      frame_action_button("ltnm_refresh", {"ltnm-gui.refresh"}),
      frame_action_button("utility/close", nil, {comp = "base", action = "close"})
    }}
  )
end

return component