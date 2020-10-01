local component = require("lib.gui-component")()

local event = require("__flib__.event")

local constants = require("constants")

component.handlers = {
  close_button = {
    on_gui_click = function(e)
      event.raise(constants.events.close_main_gui, {player_index = e.player_index})
    end
  }
}

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
      frame_action_button("ltnm_pin", {"ltnm-gui.keep-open"}),
      frame_action_button("ltnm_refresh", {"ltnm-gui.refresh"}),
      frame_action_button("utility/close", nil, {"base", "titlebar", "close_button"})
    }}
  )
end

return component