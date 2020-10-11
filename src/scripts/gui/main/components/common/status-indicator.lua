return function(name, count, dark, width)
  return (
    {type = "flow", horizontal_align = "center", vertical_align = "center", width = width, children = {
      {type = "sprite", style = "ltnm_status_icon", sprite = "ltnm_indicator_"..name},
      {type = "label", style = dark and "ltnm_black_label" or "label", caption = count}
    }}
  )
end