-- Lua queue implementation
-- based on "Queues and Double Queues" from `Programming in Lua`: http://www.lua.org/pil/11.4.html
-- modifications: changed naming conventions, added pop_at(), pop_multi(), iter_left(), iter_right(), and length()
local queue = {}

function queue.new()
  return {first = 0, last = -1}
end

function queue.push_left(tbl, value)
  local first = tbl.first - 1
  tbl.first = first
  tbl[first] = value
end

function queue.push_right(tbl, value)
  local last = tbl.last + 1
  tbl.last = last
  tbl[last] = value
end

function queue.pop_left(tbl)
  local first = tbl.first
  if first > tbl.last then error("list is empty") end
  local value = tbl[first]
  tbl[first] = nil        -- to allow garbage collection
  tbl.first = first + 1
  return value
end

function queue.pop_right(tbl)
  local last = tbl.last
  if tbl.first > last then error("list is empty") end
  local value = tbl[last]
  tbl[last] = nil         -- to allow garbage collection
  tbl.last = last - 1
  return value
end

-- use sparingly, has a similar overhead to table.remove()
function queue.pop_at(tbl, index)
  local last = tbl.last
  local value = tbl[index]
  for i = index, last do
    tbl[i] = tbl[i + 1]
  end
  tbl.last = last - 1
  return value
end

-- even slower - use sparingly!
function queue.pop_multi(tbl, to_pop)
  local lowest
  local offset = 0
  local values = {}
  for id in pairs(to_pop) do
    if not lowest or id < lowest then
      values[id] = queue.pop_at(tbl, id)
      lowest = id
    else
      values[id] = queue.pop_at(tbl, id - offset)
    end
    offset = offset + 1
  end
  return values
end

function queue.iter_left(tbl)
  local i = tbl.first - 1
  return function()
    if i < tbl.last then
      i = i + 1
      return i, tbl[i]
    end
  end
end

function queue.iter_right(tbl)
  local i = tbl.last + 1
  return function()
    if i > tbl.first then
      i = i - 1
      return i, tbl[i]
    end
  end
end

function queue.length(tbl)
  return math.abs(tbl.last - tbl.first + 1)
end

return queue