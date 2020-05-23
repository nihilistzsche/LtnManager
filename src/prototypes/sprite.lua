local data_util = require("__flib__.data_util")

local util = require("prototypes.util")

-- station status indicators
local indicator_sprites = {}
for i, t in ipairs(data.raw.lamp["small-lamp"].signal_to_color_mapping) do
  indicator_sprites[i] = {
    type = "sprite",
    name = "ltnm_indicator_"..t.name,
    filename = "__core__/graphics/gui-new.png",
    position = {128, 96},
    size = 28,
    scale = 0.5,
    shift = {0, 1},
    tint = t.color,
    flags = {"icon"}
  }
end
data:extend(indicator_sprites)

data:extend{
  data_util.build_sprite("ltnm_refresh_black", {0, 0}, util.paths.nav_icons, 32),
  data_util.build_sprite("ltnm_refresh_white", {32, 0}, util.paths.nav_icons, 32),
  data_util.build_sprite("ltnm_pin_black", {0, 32}, util.paths.nav_icons, 32),
  data_util.build_sprite("ltnm_pin_white", {32, 32}, util.paths.nav_icons, 32),
}