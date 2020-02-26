-- -------------------------------------------------------------------------------------------------------------------------------------------------------------
-- PROTOTYPE UPDATES

-- train map representations
local representations = {}
local default_representation = {
  filename = '__core__/graphics/gui-new.png',
  position = {128,96},
  size = 20,
  scale = 0.5,
  shift = {0,1},
  tint = {255,50,50},
  flags = {'icon'}
}
for _,t in ipairs{'locomotive', 'cargo-wagon', 'fluid-wagon', 'artillery-wagon'} do
  for _,data in pairs(data.raw[t]) do
    local sprite = data.minimap_representation or table.deepcopy(default_representation)
    sprite.type = 'sprite'
    sprite.name = 'ltnm_train_icon_'..data.name
    representations[#representations+1] = sprite
  end
end
data:extend(representations)