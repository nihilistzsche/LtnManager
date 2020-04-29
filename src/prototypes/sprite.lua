-- -------------------------------------------------------------------------------------------------------------------------------------------------------------
-- SPRITES

local util = require("prototypes.util")

-- station status indicators
local indicator_sprites = {}
for i, t in ipairs(data.raw.lamp["small-lamp"].signal_to_color_mapping) do
  indicator_sprites[i] = {
    type = "sprite",
    name = "ltnm_indicator_"..t.name,
    filename = "__core__/graphics/gui-new.png",
    position = {128,96},
    size = 28,
    scale = 0.5,
    shift = {0,1},
    tint = t.color,
    flags = {"icon"}
  }
end
data:extend(indicator_sprites)

data:extend{
  util.mipped_icon("ltnm_close_black", {0,0}, util.paths.nav_icons, 40),
  util.mipped_icon("ltnm_close_white", {60,0}, util.paths.nav_icons, 40),
  util.mipped_icon("ltnm_refresh_black", {0,40}, util.paths.nav_icons, 40),
  util.mipped_icon("ltnm_refresh_white", {60,40}, util.paths.nav_icons, 40),
  util.mipped_icon("ltnm_pin_black", {0,80}, util.paths.nav_icons, 40),
  util.mipped_icon("ltnm_pin_white", {60,80}, util.paths.nav_icons, 40),
  util.mipped_icon("ltnm_search_black", {0,120}, util.paths.nav_icons, 40),
  util.mipped_icon("ltnm_search_white", {60,120}, util.paths.nav_icons, 40)
}