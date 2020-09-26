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

local function frame_action_button(sprite, tooltip, handlers, save_as)
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

component.base_template = (
  {type = "flow", handlers_prefix = "titlebar.", save_as_prefix = "titlebar.", save_as = "flow", children = {
    {type = "label", style = "frame_title", caption = {"mod-name.LtnManager"}, ignored_by_interaction = true},
    {type = "empty-widget", style = "flib_titlebar_drag_handle", ignored_by_interaction = true},
    frame_action_button("ltnm_pin", {"ltnm-gui.keep-open"}),
    frame_action_button("ltnm_refresh", {"ltnm-gui.refresh"}),
    frame_action_button("utility/close", nil, "close_button")
  }}
)

return component