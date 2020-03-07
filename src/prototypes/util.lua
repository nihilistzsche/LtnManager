-- -------------------------------------------------------------------------------------------------------------------------------------------------------------
-- DATA STAGE UTILITIES

local util = require('__core__.lualib.util')

function util.mipped_icon(name, position, filename, size, mipmap_count, mods)
  local def = {
    type = 'sprite',
    name = name,
    filename = filename,
    position = position,
    size = size or 32,
    mipmap_count = mipmap_count or 2,
    flags = {'icon'}
  }
  if mods then
    for k,v in pairs(mods) do
      def[k] = v
    end
  end
  return def
end

util.paths = {
  nav_icons = '__LtnManager__/graphics/gui/nav-icons.png',
  tool_icons = '__LtnManager__/graphics/gui/tool-icons.png',
  shortcut_icons = '__LtnManager__/graphics/shortcut/ltn-manager-shortcut.png'
}

util.empty_checkmark = {
  filename = '__core__/graphics/empty.png',
  priority = 'very-low',
  width = 1,
  height = 1,
  frame_count = 1,
  scale = 8
}

return util