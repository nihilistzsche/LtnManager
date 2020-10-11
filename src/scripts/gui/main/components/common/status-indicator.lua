return function(name, count, dark, width)
  return (
    {type = "flow", horizontal_align = "center", vertical_align = "center", width = width, children = {
      {type = "sprite", style = "status_image", sprite = "ltnm_status_"..name},
      {type = "label", style = dark and "ltnm_black_label" or "label", caption = count}
    }}
  )
end