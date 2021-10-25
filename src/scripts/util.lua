local gui = require("__flib__.gui")
local misc = require("__flib__.misc")

local util = {}

--- Create a flying text at the player's cursor with an error sound.
--- @param player LuaPlayer
--- @param message LocalisedString
function util.error_flying_text(player, message)
  player.create_local_flying_text{create_at_cursor = true, text = message}
  player.play_sound{path = "utility/cannot_build"}
end

function util.gui_list(parent, iterator, test, build, update, ...)
  local children = parent.children
  local i = 0

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

  for j = i + 1, #children do
    children[j].destroy()
  end
end

--- Updates a slot table based on the current items.
--- @param table LuaGuiElement
--- @param source table
--- @param dictionaries table
function util.slot_table_update(table, source, dictionaries)
  local children = table.children

  local i = 0
  for name, count in pairs(source or {}) do
    i = i + 1
    local button = children[i]
    if not button then
      local sprite = string.gsub(name, ",", "/")
      button = gui.add(table, {
          type = "sprite-button",
          style = "ltnm_small_slot_button_default",
          sprite = sprite,
          tooltip = "[img="
            ..sprite
            .."]  [font=default-semibold]"
            ..dictionaries.materials[name]
            .."[/font]\n"
            ..misc.delineate_number(count),
          number = count,
      })
    end
  end

  for i = i + 1, #children do
    children[i].destroy()
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
