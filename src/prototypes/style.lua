local styles = data.raw["gui-style"]["default"]

-- BUTTON STYLES

styles.ltnm_depot_button = {
  type = "button_style",
  parent = "button",
  -- ! TODO this is temporary - remove it!!!
  width = 194,
  -- !
  height = 85,
  padding = 4,
  -- horizontally_stretchable = "on",
  horizontally_squashable = "on",
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

-- FLOW STYLES

styles.ltnm_tab_horizontal_flow = {
  type = "horizontal_flow_style",
  horizontal_spacing = 12,
  left_padding = 12,
  right_padding = 12,
  bottom_padding = 12
}

-- FRAME STYLES

-- SCROLL PANE STYLES

styles.ltnm_depot_select_scroll_pane = {
  type = "scroll_pane_style",
  parent = "flib_naked_scroll_pane_no_padding",
  width = 206,
  height = 510,
  background_graphical_set = {
    position = {282, 17},
    corner_size = 8,
    overall_tiling_horizontal_padding = 4,
    overall_tiling_horizontal_size = 198,
    overall_tiling_horizontal_spacing = 8,
    overall_tiling_vertical_padding = 4,
    overall_tiling_vertical_size = 77,
    overall_tiling_vertical_spacing = 8
  },
  vertical_flow_style = {
    type = "vertical_flow_style",
    vertical_spacing = 0
  }
}