local gui = require("__flib__.gui-beta")

local util = {}

function util.gui_list(parent, iterator, test, build, update, ...)
  local children = parent.children
  local i = 0

  -- create or update items
  for k, v in table.unpack(iterator) do
    local passed = test(v, k, i, ...)
    if passed then
      i = i + 1
      local child = children[i]
      if not child then
        gui.build(parent, {build(...)})
        child = parent.children[i]
      end
      gui.update(child, update(v, k, i, ...))
    end
  end

  -- destroy extraneous items
  for j = i + 1, #children do
    children[j].destroy()
  end
end

function util.sorted_iterator(arr, src_tbl, sort_state)
  local step = sort_state and 1 or -1
  local i = sort_state and 1 or #arr

  return
    function()
      local j = i + step
      if arr[j] then
        i = j
        local arr_value = arr[j]
        return arr_value, src_tbl[arr_value]
      end
    end,
    arr
end

return util
