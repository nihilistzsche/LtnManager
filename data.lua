local data_util = require("__flib__.data-util")

local util = require("prototypes.util")

data:extend({
  -- custom inputs
  {
    type = "custom-input",
    name = "ltnm-toggle-gui",
    key_sequence = "CONTROL + T",
  },
  {
    type = "custom-input",
    name = "ltnm-linked-focus-search",
    key_sequence = "",
    linked_game_control = "focus-search",
  },
  -- shortcuts
  {
    type = "shortcut",
    name = "ltnm-toggle-gui",
    icon = util.paths.shortcut_icon,
    icon_size = 32,
    small_icon = util.paths.shortcut_icon_small,
    small_icon_size = 24,



    --icon = data_util.build_sprite(nil, { 0, 0 }, util.paths.shortcut_icons, 32),
    --disabled_icon = data_util.build_sprite(nil, { 48, 0 }, util.paths.shortcut_icons, 32),
    --small_icon = data_util.build_sprite(nil, { 0, 32 }, util.paths.shortcut_icons, 24),
    --disabled_small_icon = data_util.build_sprite(nil, { 36, 32 }, util.paths.shortcut_icons, 24),
    toggleable = true,
    action = "lua",
    associated_control_input = "ltnm-toggle-gui",
    technology_to_unlock = "logistic-train-network",
  },
})

require("prototypes.sprite")
require("prototypes.style")
