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

function templates.small_slot_table(widths, color, name)
  return {
    type = "frame",
    name = name.."_frame",
    style = "ltnm_small_slot_table_frame_"..color,
    style_mods = {width = widths[name]},
    {type = "table", name = name.."_table", style = "slot_table", column_count = widths[name.."_columns"]},
  }
end

--- Creates a column header with a sort toggle.
--- @param widths table
--- @param tab string
--- @param column string
--- @param selected boolean
--- @param tooltip string|nil
function templates.sort_checkbox(widths, tab, column, selected, tooltip)
  return {
    type = "checkbox",
    style = selected and "ltnm_selected_sort_checkbox" or "ltnm_sort_checkbox",
    style_mods = {width = widths[tab][column]},
    caption = {"gui.ltnm-"..string.gsub(column, "_", "-")},
    tooltip = tooltip,
    state = false,
    ref = {tab, "toolbar", column.."_checkbox"},
    actions = {
      on_checked_state_changed = {gui = "main", tab = tab, action = "toggle_sort", column = column},
    }
  }
end

function templates.status_indicator(width)
  return
    {type = "flow", style = "flib_indicator_flow", style_mods = {width = width},
      {type = "sprite", style = "flib_indicator"},
      {type = "label"}
    }
end

return templates
