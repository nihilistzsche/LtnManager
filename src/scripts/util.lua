local gui = require("__flib__.gui-beta")

local misc_util = require("__flib__.misc")

local util = {}

function util.material_button_tooltip(translations, name, count)
  return (
    "[img="..string.gsub(name, ",", "/")
    .."]  [font=default-bold]"
    ..translations.materials[name]
    .."[/font]"
    .."\n"
    .."[font=default-semibold]"
    ..translations.gui.count
    .."[/font] "
    ..misc_util.delineate_number(math.floor(count))
  )
end

function util.get_gui_data(player_index)
  local player = game.get_player(player_index)
  local player_table = global.players[player_index]
  local gui_data = player_table.gui.main

  return player, player_table, gui_data.state, gui_data.refs
end

function util.generate_component_handlers(component_name, handlers)
  local new_handlers = {}
  for name, handler in pairs(handlers) do
    new_handlers[component_name.."_"..name] = handler
  end
  return new_handlers
end

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