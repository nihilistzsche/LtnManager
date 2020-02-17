-- -------------------------------------------------------------------------------------------------------------------------------------------------------------
-- PROTOTYPES

local styles = data.raw['gui-style'].default

-- -----------------------------------------------------------------------------
-- BUTTON STYLES

local tileset = '__LtnManager__/graphics/gui/button-tileset.png'

local function slot_button(y, glow_color, default_x)
  return {
    type = 'button_style',
    parent = 'quick_bar_slot_button',
    default_graphical_set = {
      base = {border=4, position={(default_x or 0),y}, size=80, filename=tileset},
      shadow = offset_by_2_rounded_corners_glow(default_dirt_color),
    },
    hovered_graphical_set = {
      base = {border=4, position={80,y}, size=80, filename=tileset},
      shadow = offset_by_2_rounded_corners_glow(default_dirt_color),
      glow = offset_by_2_rounded_corners_glow(glow_color)
    },
    clicked_graphical_set = {
      base = {border=4, position={160,y}, size=80, filename=tileset},
      shadow = offset_by_2_rounded_corners_glow(default_dirt_color),
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
  styles['ltnm_active_slot_button_'..data.name] = slot_button(data.y, data.glow, 80)
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

-- -----------------------------------------------------------------------------
-- SCROLL PANE STYLES

styles.ltnm_depots_scroll_pane = {
  type = 'scroll_pane_style',
  parent = 'scroll_pane_with_dark_background_under_subheader',
  height = 600,
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
  extra_padding_when_activated = 0
}

-- -----------------------------------------------------------------------------
-- TABBED PANE STYLES

styles.ltnm_tabbed_pane = {
  type = 'tabbed_pane_style',
  parent = 'tabbed_pane',
  tab_content_frame = {
    type = 'frame_style',
    top_padding = 8,
    right_padding = 8,
    bottom_padding = 4,
    left_padding = 8,
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