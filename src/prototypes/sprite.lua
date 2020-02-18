-- -------------------------------------------------------------------------------------------------------------------------------------------------------------
-- SPRITES

local icons_tileset = '__LtnManager__/graphics/gui/icons.png'

-- indicator sprites
local indicator_sprites = {}
for i,t in ipairs(data.raw.lamp['small-lamp'].signal_to_color_mapping) do
  -- indicator_sprites[i] = {
  --   type = 'sprite',
  --   name = 'ltnm_indicator_'..t.name,
  --   filename = icons_tileset,
  --   position = {0,0},
  --   size = 28,
  --   tint = t.color,
  --   flags = {'icon'}
  -- }
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