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

-- add commas to separate thousands
-- from lua-users.org: http://lua-users.org/wiki/FormattingNumbers
function util.comma_value(input)
  local formatted = input
  while true do
    formatted, k = string.gsub(formatted, "^(-?%d+)(%d%d%d)", '%1,%2')
    if (k==0) then
      break
    end
  end
  return formatted
end

-- convert a number of ticks into runtime
-- this assumes only minutes and seconds, hours are unneeded for our usecase
function util.ticks_to_time(ticks)
  local seconds = math.floor(ticks / 60)
  return math.floor(seconds / 60)..':'..math.floor(seconds % 60)
end

return util