local component = {}

function component.build(width, black)
  return (
    {
      type = "flow",
      style_mods = {horizontal_align = "center", vertical_align = "center", width = width},
      children = {
        {type = "sprite", name = "icon", style = "flib_indicator"},
        {type = "label", name = "label", style = black and "ltnm_black_label" or "label"}
      }
    }
  )
end

function component.build_for_list()
  return component.build(nil, true)
end

function component.update(count, name)
  return (
    {children = {
      {elem_mods = {sprite = "flib_indicator_"..name}},
      {elem_mods = {caption = count}}
    }}
  )
end

return component