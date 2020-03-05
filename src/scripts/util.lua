-- -------------------------------------------------------------------------------------------------------------------------------------------------------------
-- CONTROL STAGE UTILITIES

local util = require('__core__.lualib.util')

-- adds the contents of two material tables together
-- t1 contains the items we are adding into the table, t2 will be returned
function util.add_materials(t1, t2)
  for name,count in pairs(t1) do
    local existing = t2[name]
    if existing then
      t2[name] = existing + count
    else
      t2[name] = count
    end
  end
  return t2
end

return util