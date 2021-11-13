local data_util = require("__flib__.data-util")

local util = require("prototypes.util")

data:extend({
  data_util.build_sprite("ltnm_pin_black", { 0, 32 }, util.paths.nav_icons, 32),
  data_util.build_sprite("ltnm_pin_white", { 32, 32 }, util.paths.nav_icons, 32),
  data_util.build_sprite("ltnm_refresh_black", { 0, 0 }, util.paths.nav_icons, 32),
  data_util.build_sprite("ltnm_refresh_white", { 32, 0 }, util.paths.nav_icons, 32),
})
