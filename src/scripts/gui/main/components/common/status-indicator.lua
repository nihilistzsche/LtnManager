return function(name, count, dark, width)
  local color = string.gsub(name, "signal%-", "")
  return (
    {type = "flow", horizontal_align = "center", vertical_align = "center", width = width, children = {
      {type = "sprite", style = "flib_indicator", sprite = "flib_indicator_"..color},
      {type = "label", style = dark and "ltnm_black_label" or "label", caption = count}
    }}
  )
end