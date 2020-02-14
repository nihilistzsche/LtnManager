-- -------------------------------------------------------------------------------------------------------------------------------------------------------------
-- PROTOTYPES

local styles = data.raw['gui-style'].default

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