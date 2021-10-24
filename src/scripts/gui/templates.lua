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

--- Creates a column header with a sort toggle.
--- @param widths table
--- @param tab string
--- @param column string
--- @param state boolean
--- @param tooltip string|nil
function templates.sort_checkbox(widths, tab, column, state, tooltip)
  return {
    type = "checkbox",
    style = "ltnm_sort_checkbox",
    style_mods = {width = widths[tab][column]},
    caption = {"gui.ltnm-"..column},
    tooltip = tooltip,
    state = state,
    ref = {tab, "toolbar", column.."_checkbox"},
    actions = {
      on_checked_state_changed = {gui = "main", tab = tab, action = "toggle_sort", column = column},
    }
  }
end

return templates
