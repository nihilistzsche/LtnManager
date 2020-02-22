-- -------------------------------------------------------------------------------------------------------------------------------------------------------------
-- GUI STYLES

local styles = data.raw['gui-style'].default

-- -----------------------------------------------------------------------------
-- BUTTON STYLES

local slot_buttons_tileset = '__LtnManager__/graphics/gui/slot-buttons.png'

local function slot_button(y, glow_color, default_x)
  return {
    type = 'button_style',
    parent = 'quick_bar_slot_button',
    default_graphical_set = {
      base = {border=4, position={(default_x or 0),y}, size=80, filename=slot_buttons_tileset},
      shadow = offset_by_2_rounded_corners_glow(default_dirt_color),
    },
    hovered_graphical_set = {
      base = {border=4, position={80,y}, size=80, filename=slot_buttons_tileset},
      shadow = offset_by_2_rounded_corners_glow(default_dirt_color),
      glow = offset_by_2_rounded_corners_glow(glow_color)
    },
    clicked_graphical_set = {
      base = {border=4, position={160,y}, size=80, filename=slot_buttons_tileset},
      shadow = offset_by_2_rounded_corners_glow(default_dirt_color),
    }
  }
end

-- local row_shadow = {
--   position = {378, 103},
--   corner_size = 16,
--   top_outer_border_shift = 4,
--   bottom_outer_border_shift = -4,
--   left_outer_border_shift = 4,
--   right_outer_border_shift = -4,
--   draw_type = "outer"
-- }

local row_shadow = {
  position = {351,109},
  corner_size = 10,
  top_outer_border_shift = 4,
  bottom_outer_border_shift = -4,
  left_outer_border_shift = 4,
  right_outer_border_shift = -4,
  draw_type = 'outer'
}

local function row_slot_button(y, glow_color, default_x)
  return {
    type = 'button_style',
    size = 32,
    padding = -2,
    default_graphical_set = {
      base = {border=4, position={(default_x or 0),y}, size=80, filename=slot_buttons_tileset},
      shadow = row_shadow
    },
    hovered_graphical_set = {
      base = {border=4, position={80,y}, size=80, filename=slot_buttons_tileset},
      shadow = row_shadow,
      glow = offset_by_2_rounded_corners_glow(glow_color)
    },
    clicked_graphical_set = {
      base = {border=4, position={160,y}, size=80, filename=slot_buttons_tileset},
      shadow = row_shadow
    }
  }
end

local slot_button_data = {
  {name='dark_grey', y=0, glow=default_glow_color},
  {name='light_grey', y=80, glow=default_glow_color},
  {name='red', y=160, glow={255,166,123,128}},
  {name='green', y=240, glow={34,255,75,128}},
  {name='blue', y=320, glow={34,181,255,128}},
}

for _,data in ipairs(slot_button_data) do
  styles['ltnm_slot_button_'..data.name] = slot_button(data.y, data.glow)
  styles['ltnm_row_slot_button_'..data.name] = row_slot_button(data.y, data.glow)
  styles['ltnm_active_slot_button_'..data.name] = slot_button(data.y, data.glow, 82)
  styles['ltnm_active_row_slot_button_'..data.name] = row_slot_button(data.y, data.glow, 82)
end

-- -----------------------------------------------------------------------------
-- EMPTY WIDGET STYLES

styles.ltnm_titlebar_drag_handle = {
  type = 'empty_widget_style',
  parent = 'draggable_space_header',
  horizontally_stretchable = 'on',
  natural_height = 24,
  minimal_width = 24,
  -- right_margin = 7
}

-- -----------------------------------------------------------------------------
-- FLOW STYLES

styles.ltnm_titlebar_flow = {
  type = 'horizontal_flow_style',
  direction = 'horizontal',
  horizontally_stretchable = 'on',
  vertical_align = 'center',
  top_margin = -3
}

styles.ltnm_station_labels_flow = {
  type = 'horizontal_flow_style',
  horizontal_spacing = 12,
  vertical_align = 'center'
}

-- -----------------------------------------------------------------------------
-- FRAME STYLES

styles.ltnm_scroll_pane_frame = {
  type = 'frame_style',
  parent = 'inside_deep_frame',
  graphical_set = {
    base = {
      position = {85,0},
      corner_size = 8,
      draw_type = 'outer',
      center = {position={42,8}, size=1}
    },
    shadow = default_inner_shadow
  }
}

styles.ltnm_depot_frame = {
  type = 'frame_style',
  parent = 'dark_frame',
  left_padding = 4,
  right_padding = 4,
  horizontally_stretchable = 'on'
}

styles.ltnm_test_frame = {
  type = 'frame_style',
  margin = 4,
  graphical_set = {
    base = {
      position = {386,0},
      corner_size = 8,
      draw_type = 'outer'
    },
    shadow = default_shadow
  }
}

styles.ltnm_icon_slot_table_frame = {
  type = 'frame_style',
  padding = 0,
  graphical_set = {
    base = {
      position = {85,0},
      corner_size = 8,
      draw_type = 'outer',
      center = {position={42,8}, size=1}
    },
    shadow = default_inner_shadow
  },
  background_graphical_set = {
    base = {
      position = {282, 17},
      corner_size = 8,
      overall_tiling_horizontal_padding = 4,
      overall_tiling_horizontal_size = 32,
      overall_tiling_horizontal_spacing = 8,
      overall_tiling_vertical_padding = 4,
      overall_tiling_vertical_size = 32,
      overall_tiling_vertical_spacing = 8
    }
  },
}

styles.ltnm_station_row_frame = {
  type = 'frame_style',
  parent = 'dark_frame',
  minimal_height = 40,
  padding = 0,
  horizontally_stretchable = 'on',
  horizontal_flow_style = {
    type = 'horizontal_flow_style',
    vertical_align = 'center',
    horizontal_spacing = 12
  }
}

-- -----------------------------------------------------------------------------
-- SCROLL PANE STYLES

styles.ltnm_depots_scroll_pane = {
  type = 'scroll_pane_style',
  parent = 'scroll_pane_with_dark_background_under_subheader',
  vertically_stretchable = 'on',
  horizontally_stretchable = 'on',
  background_graphical_set = {
    position = {282, 17},
    corner_size = 8,
    overall_tiling_vertical_spacing = 12,
    overall_tiling_vertical_size = 300,
    overall_tiling_vertical_padding = 4
  }
}

styles.ltnm_icon_slot_table_scroll_pane = {
  type = 'scroll_pane_style',
  parent = 'scroll_pane',
  padding = 0,
  margin = 0,
  extra_padding_when_activated = 0,
  width = 332,
  height = 160
}

styles.ltnm_stations_scroll_pane = {
  type = 'scroll_pane_style',
  parent = 'scroll_pane_with_dark_background_under_subheader',
  vertically_stretchable = 'on'
}

-- -----------------------------------------------------------------------------
-- SPRITE STYLES



-- -----------------------------------------------------------------------------
-- TABBED PANE STYLES

styles.ltnm_tabbed_pane = {
  type = 'tabbed_pane_style',
  parent = 'tabbed_pane',
  tab_content_frame = {
    type = 'frame_style',
    top_padding = 8,
    right_padding = 12,
    bottom_padding = 8,
    left_padding = 12,
    graphical_set = tabbed_pane_graphical_set
  }
}

-- -----------------------------------------------------------------------------
-- TABLE STYLES

styles.ltnm_icon_slot_table = {
  type = 'table_style',
  parent = 'slot_table',
  horizontal_spacing = 0,
  vertical_spacing = 0
}