local data_util = require("__flib__.data-util")

local util = require("prototypes.util")

-- station status indicators
local indicator_sprites = {
  {
    type = "sprite",
    name = "ltnm_status_signal-white",
    filename = "__core__/graphics/gui-new.png",
    position = {128, 96},
    size = 28,
    scale = 0.5,
    shift = {0, 1},
    tint = {255,255,255},
    flags = {"icon"}
  }
}
for i, t in ipairs(data.raw.lamp["small-lamp"].signal_to_color_mapping) do
  indicator_sprites[i + 1] = {
    type = "sprite",
    name = "ltnm_status_"..t.name,
    filename = "__LtnManager__/graphics/gui/status.png",
    size = 32,
    scale = 0.5,
    tint = t.color,
    flags = {"icon"}
  }
end
data:extend(indicator_sprites)

data:extend{
  data_util.build_sprite("ltnm_pin_black", {0, 32}, util.paths.nav_icons, 32),
  data_util.build_sprite("ltnm_pin_white", {32, 32}, util.paths.nav_icons, 32),
  data_util.build_sprite("ltnm_refresh_black", {0, 0}, util.paths.nav_icons, 32),
  data_util.build_sprite("ltnm_refresh_white", {32, 0}, util.paths.nav_icons, 32),
  data_util.build_sprite("ltnm_search_disabled", {0, 0}, "__LtnManager__/graphics/gui/disabled-search-icon.png", 32)
}