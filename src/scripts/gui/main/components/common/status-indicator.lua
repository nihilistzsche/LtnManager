local component = {}

function component.build(width, black)
  return (
    {
      type = "flow",
      style_mods = {horizontal_align = "center", vertical_align = "center", width = width},
      ref = {"flow"},
      children = {
        {type = "sprite", name = "icon", style = "flib_indicator"},
        {type = "label", name = "label", style = black and "ltnm_black_label" or "label"}
      }
    }
  )
end

return component