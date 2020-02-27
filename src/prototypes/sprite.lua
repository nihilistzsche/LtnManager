-- -------------------------------------------------------------------------------------------------------------------------------------------------------------
-- SPRITES

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

local function mipped_icon(name, position, filename, size, mipmap_count)
  return {
    type = 'sprite',
    name = name,
    filename = filename or '__LtnManager__/graphics/gui/nav-icons.png',
    position = position,
    size = size or 32,
    mipmap_count = mipmap_count or 2,
    flags = {'icon'}
  }
end

data:extend{
  mipped_icon('ltnm_refresh_white', {0,0}),
  mipped_icon('ltnm_refresh_black', {48,0})
}