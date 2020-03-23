-- -------------------------------------------------------------------------------------------------------------------------------------------------------------
-- PROTOTYPES

local util = require('prototypes.util')

data:extend{
  -- custom inputs
  {
    type = 'custom-input',
    name = 'ltnm-toggle-gui',
    key_sequence = 'CONTROL + T'
  },
  {
    type = 'custom-input',
    name = 'ltnm-search',
    key_sequence = '',
    linked_game_control = 'focus-search'
  },
  -- shortcuts
  {
    type = 'shortcut',
    name = 'ltnm-toggle-gui',
    icon = util.mipped_icon(nil, {0,0}, util.paths.shortcut_icons, 32, 2),
    disabled_icon = util.mipped_icon(nil, {48,0}, util.paths.shortcut_icons, 32, 2),
    small_icon = util.mipped_icon(nil, {0,32}, util.paths.shortcut_icons, 24, 2),
    disabled_small_icon = util.mipped_icon(nil, {36,32}, util.paths.shortcut_icons, 24, 2),
    toggleable = true,
    action = 'lua',
    associated_control_input = 'ltnm-toggle-gui',
    technology_to_unlock = 'logistic-train-network'
  }
}

-- the rest
require('prototypes.sprite')
require('prototypes.style')

--[[
  local tile = table.deepcopy(data.raw['tile']['lab-dark-2'])
  tile.name = 'ltnm-frame-tile'
  tile.map_color = {64, 63, 64}
  data:extend{tile}

  local rail = table.deepcopy(data.raw['straight-rail']['straight-rail'])
  rail.name = 'ltnm-frame-rail'
  rail.order = 'z'
  rail.map_color = {r=64, g=63, b=64}
  rail.friendly_map_color = {r=64, g=63, b=64}
  rail.enemy_map_color = {r=64, g=63, b=64}
  data:extend{rail}
]]