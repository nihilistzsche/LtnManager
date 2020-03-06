-- -------------------------------------------------------------------------------------------------------------------------------------------------------------
-- SPRITES

local util = require('prototypes.util')

-- station status indicators
local indicator_sprites = {}
for i,t in ipairs(data.raw.lamp['small-lamp'].signal_to_color_mapping) do
  indicator_sprites[i] = {
    type = 'sprite',
    name = 'ltnm_indicator_'..t.name,
    filename = '__core__/graphics/gui-new.png',
    position = {128,96},
    size = 28,
    scale = 0.5,
    shift = {0,1},
    tint = t.color,
    flags = {'icon'}
  }
end
data:extend(indicator_sprites)

data:extend{
  util.mipped_icon('ltnm_refresh_white', {0,0}, util.paths.nav_icons),
  util.mipped_icon('ltnm_refresh_black', {48,0}, util.paths.nav_icons),
  util.mipped_icon('ltnm_filter', {0,0}, util.paths.tool_icons),
  util.mipped_icon('ltnm_mod_gui_button_icon', {0,0}, util.paths.shortcut_icons)
}