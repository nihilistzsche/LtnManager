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
    icon = data_util.build_sprite(nil, { 0, 0 }, util.paths.shortcut_icons, 32, 2),
    disabled_icon = data_util.build_sprite(nil, { 48, 0 }, util.paths.shortcut_icons, 32, 2),
    small_icon = data_util.build_sprite(nil, { 0, 32 }, util.paths.shortcut_icons, 24, 2),
    disabled_small_icon = data_util.build_sprite(nil, { 36, 32 }, util.paths.shortcut_icons, 24, 2),
    toggleable = true,
    action = "lua",
    associated_control_input = "ltnm-toggle-gui",
    technology_to_unlock = "logistic-train-network",
  },
})

require("prototypes.sprite")
require("prototypes.style")
