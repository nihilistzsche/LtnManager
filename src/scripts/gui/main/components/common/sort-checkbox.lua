local constants = require("constants")

local component = {}

function component.build(widths, comp_name, sort_name, caption, tooltip)
  return {
    type = "checkbox",
    style = "ltnm_sort_checkbox",
    style_mods = {width = widths[sort_name]},
    caption = {"ltnm-gui."..caption},
    tooltip = tooltip and {"ltnm-gui."..tooltip.."-tooltip"} or nil,
    state = false,
    handlers = {
      on_click = "main_"..comp_name.."_toggle_sort",
    },
    tags = {sort_name = sort_name}
  }
end

return component