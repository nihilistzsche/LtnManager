-- -------------------------------------------------------------------------------------------------------------------------------------------------------------
-- DATA STAGE UTILITIES

local util = require('__core__.lualib.util')

function util.mipped_icon(name, position, filename, size, mipmap_count)
  return {
    type = 'sprite',
    name = name,
    filename = filename,
    position = position,
    size = size or 32,
    mipmap_count = mipmap_count or 2,
    flags = {'icon'}
  }
end

return util