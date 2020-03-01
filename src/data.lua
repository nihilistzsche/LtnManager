-- -------------------------------------------------------------------------------------------------------------------------------------------------------------
-- PROTOTYPES

-- debug adapter
pcall(require,'__debugadapter__/debugadapter.lua')

require('prototypes/sprite')
require('prototypes/style')

-- MISC

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