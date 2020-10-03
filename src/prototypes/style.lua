local constants = require("constants")

local util = require("prototypes.util")

local styles = data.raw["gui-style"]["default"]

-- BUTTON STYLES

-- smaller flib slot buttons
for _, color in ipairs{"default", "red", "green", "blue"} do
  styles["ltnm_small_slot_button_"..color] = {
    type = "button_style",
    parent = "flib_slot_button_"..color,
    size = 36
  }
  styles["ltnm_selected_small_slot_button_"..color] = {
    type = "button_style",
    parent = "flib_selected_slot_button_"..color,
    size = 36
  }
end

styles.ltnm_depot_button = {
  type = "button_style",
  parent = "button",
  width = 206,
  height = 89,
  padding = 4,
  top_padding = 1,
  hovered_font_color = button_hovered_font_color,
  hovered_graphical_set = {
    base = {position = {34, 17}, corner_size = 8},
    shadow = default_dirt,
  },
  disabled_font_color = button_hovered_font_color,
  disabled_graphical_set = {
    base = {position = {225, 17}, corner_size = 8},
    shadow = default_dirt
  }
}

-- CHECKBOX STYLES

-- inactive is grey until hovered
-- checked = descending, unchecked = ascending
styles.ltnm_sort_checkbox = {
  type = "checkbox_style",
  font = "default-bold",
  font_color = bold_font_color,
  padding = 0,
  default_graphical_set = {
    filename = "__core__/graphics/arrows/table-header-sort-arrow-up-white.png",
    size = {16, 16},
    scale = 0.5
  },
  hovered_graphical_set = {
    filename = "__core__/graphics/arrows/table-header-sort-arrow-up-hover.png",
    size = {16, 16},
    scale = 0.5
  },
  clicked_graphical_set = {
    filename = "__core__/graphics/arrows/table-header-sort-arrow-up-white.png",
    size = {16, 16},
    scale = 0.5
  },
  disabled_graphical_set = {
    filename = "__core__/graphics/arrows/table-header-sort-arrow-up-white.png",
    size = {16, 16},
    scale = 0.5
  },
  selected_graphical_set = {
    filename = "__core__/graphics/arrows/table-header-sort-arrow-down-white.png",
    size = {16, 16},
    scale = 0.5
  },
  selected_hovered_graphical_set = {
    filename = "__core__/graphics/arrows/table-header-sort-arrow-down-hover.png",
    size = {16, 16},
    scale = 0.5
  },
  selected_clicked_graphical_set = {
    filename = "__core__/graphics/arrows/table-header-sort-arrow-down-white.png",
    size = {16, 16},
    scale = 0.5
  },
  selected_disabled_graphical_set = {
    filename = "__core__/graphics/arrows/table-header-sort-arrow-down-white.png",
    size = {16, 16},
    scale = 0.5
  },
  checkmark = util.empty_checkmark,
  disabled_checkmark = util.empty_checkmark,
  text_padding = 5
}

-- selected is orange by default
styles.ltnm_selected_sort_checkbox = {
  type = "checkbox_style",
  parent = "ltnm_sort_checkbox",
  -- font_color = bold_font_color,
  default_graphical_set = {
    filename = "__core__/graphics/arrows/table-header-sort-arrow-up-active.png",
    size = {16, 16},
    scale = 0.5
  },
  selected_graphical_set = {
    filename = "__core__/graphics/arrows/table-header-sort-arrow-down-active.png",
    size = {16, 16},
    scale = 0.5
  }
}

-- EMPTY WIDGET STYLES

styles.ltnm_table_header_spacer = {
  type = "empty_widget_style",
  width = 12
}

-- FLOW STYLES

styles.ltnm_tab_horizontal_flow = {
  type = "horizontal_flow_style",
  horizontal_spacing = 12,
  left_padding = 12,
  right_padding = 12,
  bottom_padding = 12
}

styles.ltnm_depot_button_inner_flow = {
  type = "vertical_flow_style",
  vertical_spacing = 0
}

styles.ltnm_train_status_flow = {
  type = "vertical_flow_style",
  vertical_spacing = 0,
  vertical_align = "center"
}

-- FRAME STYLES

styles.ltnm_table_row_frame = {
  type = "frame_style",
  parent = "statistics_table_item_frame",
  top_padding = 2,
  bottom_padding = 2,
  left_padding = 10,
  right_padding = 0, -- padding will be handled by the slot table
  height = 52,
  horizontal_flow_style = {
    type = "horizontal_flow_style",
    vertical_align = "center",
    horizontal_spacing = 12,
  }
}

styles.ltnm_table_toolbar_frame = {
  type = "frame_style",
  parent = "subheader_frame",
  left_padding = 12,
  right_padding = 24, -- two scroll bars' worth
  horizontal_flow_style = {
    type = "horizontal_flow_style",
    horizontal_spacing = 12,
    vertical_align = "center"
  }
}

-- IMAGE STYLES

styles.ltnm_status_icon = {
  type = "image_style",
  stretch_image_to_widget_size = true,
  size = 14
}

-- LABEL STYLES

styles.ltnm_black_label = {
  type = "label_style",
  parent = "label",
  font_color = button_default_font_color
}

styles.ltnm_bold_black_label = {
  type = "label_style",
  parent = "bold_label",
  font_color = button_default_bold_font_color
}

local hovered_label_color = {
  r = 0.5 * (1 + default_orange_color.r),
  g = 0.5 * (1 + default_orange_color.g),
  b = 0.5 * (1 + default_orange_color.b)
}

styles.ltnm_clickable_bold_label = {
  type = "label_style",
  parent = "bold_label",
  hovered_font_color = hovered_label_color,
  disabled_font_color = hovered_label_color
}

styles.ltnm_clickable_label = {
  type = "label_style",
  parent = "ltnm_clickable_bold_label",
  font = "default"
}

styles.ltnm_bold_green_label = {
  type = "label_style",
  parent = "bold_label",
  font_color = constants.colors.green.tbl
}

styles.ltnm_bold_red_label = {
  type = "label_style",
  parent = "bold_label",
  font_color = constants.colors.error.tbl
}

styles.ltnm_semibold_black_label = {
  type = "label_style",
  parent = "bold_label",
  font = "default-semibold",
  font_color = button_default_font_color
}

-- SCROLL PANE STYLES

styles.ltnm_depot_select_scroll_pane = {
  type = "scroll_pane_style",
  parent = "flib_naked_scroll_pane_no_padding",
  width = 206,
  height = 623,
  background_graphical_set = {
    position = {282, 17},
    corner_size = 8,
    overall_tiling_horizontal_padding = 6,
    overall_tiling_vertical_padding = 6,
    overall_tiling_vertical_size = 77,
    overall_tiling_vertical_spacing = 12
  },
  vertical_flow_style = {
    type = "vertical_flow_style",
    vertical_spacing = 0
  }
}

styles.ltnm_small_slot_table_scroll_pane = {
  type = "scroll_pane_style",
  parent = "flib_naked_scroll_pane",
  padding = 0,
  margin = 0,
  extra_padding_when_activated = 0,
  minimal_height = 36,
  background_graphical_set = {
    base = {
      position = {282, 17},
      corner_size = 8,
      overall_tiling_horizontal_padding = 4,
      overall_tiling_horizontal_size = 28,
      overall_tiling_horizontal_spacing = 8,
      overall_tiling_vertical_padding = 4,
      overall_tiling_vertical_size = 28,
      overall_tiling_vertical_spacing = 8
    }
  }
}

styles.ltnm_table_scroll_pane = {
  type = "scroll_pane_style",
  extra_padding_when_activated = 0,
  padding = 0,
  horizontally_stretchable = "on",
  vertically_stretchable = "on",
  graphical_set = {
    shadow = default_inner_shadow
  },
  background_graphical_set = {
    position = {282, 17},
    corner_size = 8,
    overall_tiling_horizontal_padding = 6,
    overall_tiling_vertical_padding = 6,
    overall_tiling_vertical_size = 40,
    overall_tiling_vertical_spacing = 12
  },
  vertical_flow_style = {
    type = "vertical_flow_style",
    vertical_spacing = 0
  }
}