local gui = require("__flib__.gui3")
local misc = require("__flib__.misc")

local util = require("scripts.util")

local component = gui.component()

local tooltip_funcs = {
  ltn_control_signal = function(translations, name, count)
    return (
    "[img=virtual-signal/"
    ..name
    .."]  [font=default-bold]"
    ..translations.virtual_signals[name]
    .."[/font]"
    .."\n"
    .."[font=default-semibold]"
    ..translations.gui.count
    .."[/font] "
    ..misc.delineate_number(math.floor(count))
  )
  end,
  material = util.material_button_tooltip,
}

function component.view(translations, width, contents)
  local columns = width / 36

  local buttons = {}
  local i = 0

  for _, data in pairs(contents) do
    if data.contents then
      local color = data.color
      local enabled = data.enabled
      local sprite_class = data.sprite_class
      local tooltip_func = tooltip_funcs[data.tooltip]
      for name, count in pairs(data.contents) do
        i = i + 1
        buttons[i] = {
          type = "sprite-button",
          style = "ltnm_small_slot_button_"..color,
          sprite = sprite_class and sprite_class.."/"..name or string.gsub(name, ",", "/"),
          number = count,
          tooltip = tooltip_func(translations, name, count),
          enabled = enabled
        }
      end
    end
  end

  return (
    {
      type = "frame",
      style = "ltnm_small_slot_table_frame",
      children = {
        {type = "table", style = "slot_table", width = width, column_count = columns, children = buttons}
      }
    }
  )
end

return component