local gui = require("__flib__.gui")
local misc = require("__flib__.misc")

local util = {}

--- Create a flying text at the player's cursor with an error sound.
--- @param player LuaPlayer
--- @param message LocalisedString
function util.error_flying_text(player, message)
  player.create_local_flying_text({ create_at_cursor = true, text = message })
  player.play_sound({ path = "utility/cannot_build" })
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
        gui.build(parent, { build(...) })
        child = parent.children[i]
      end
      gui.update(child, update(v, k, i, ...))
    end
  end

  for j = i + 1, #children do
    children[j].destroy()
  end
end

--- A dataset to put into a slot table.
---
--- If `type` is provided, it will be used for the sprite definition. If not provided, the type will be derived from the
--- name of each material.
--- @class SlotTableDef
--- @field color string
--- @field entries table<string, number>
--- @field translations table
--- @field type string|nil

--- Updates a slot table based on the passed criteria.
--- @param table LuaGuiElement
--- @param sources SlotTableDef[]
function util.slot_table_update(table, sources)
  local children = table.children

  local i = 0
  for _, source_data in pairs(sources) do
    if source_data.entries then
      for name, count in pairs(source_data.entries) do
        local sprite
        if source_data.type then
          sprite = source_data.type .. "/" .. name
        else
          sprite = string.gsub(name, ",", "/")
        end
        if game.is_valid_sprite_path(sprite) then
          i = i + 1
          local button = children[i]
          if not button then
            button = gui.add(table, { type = "sprite-button", enabled = false })
          end
          button.style = "ltnm_small_slot_button_" .. source_data.color
          button.sprite = sprite
          button.tooltip = "[img="
            .. sprite
            .. "]  [font=default-semibold]"
            .. source_data.translations[name]
            .. "[/font]\n"
            .. misc.delineate_number(count)
          button.number = count
        end
      end
    end
  end

  for i = i + 1, #children do
    children[i].destroy()
  end
end

function util.sorted_iterator(arr, src_tbl, sort_state)
  local step = sort_state and 1 or -1
  local i = sort_state and 1 or #arr

  return function()
    local j = i + step
    if arr[j] then
      i = j
      local arr_value = arr[j]
      return arr_value, src_tbl[arr_value]
    end
  end,
    arr
end

local MAX_INT = 2147483648 -- math.pow(2, 31)
function util.signed_int32(val)
  return (val >= MAX_INT and val - (2 * MAX_INT)) or val
end

return util
