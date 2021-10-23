local templates = {}

function templates.frame_action_button(sprite, tooltip, ref, action)
  return {
    type = "sprite-button",
    style = "frame_action_button",
    sprite = sprite.."_white",
    hovered_sprite = sprite.."_black",
    clicked_sprite = sprite.."_black",
    mouse_button_filter = {"left"},
    tooltip = tooltip,
    ref = ref,
    actions = {on_click = action},
  }
end

function templates.sort_checkbox(caption, state, ref, action)
  return {
    type = "checkbox",
    style = "ltnm_sort_checkbox",
    caption = caption,
    state = state,
    ref = ref,
    actions = {
      on_checked_state_changed = action,
    }
  }
end

return templates
