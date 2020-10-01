local component = require("lib.gui-component")()

function component.build()
  return (
    {type = "frame", style = "subheader_frame", bottom_margin = 12, children = {
      {type = "label", style = "subheader_caption_label", right_margin = 8, caption = "Search:"},
      {type = "textfield", lose_focus_on_confirm = true, clear_and_focus_on_right_click = true, text = ""},
      {type = "empty-widget", style = "flib_horizontal_pusher"},
      {type = "label", style = "subheader_caption_label", right_margin = 8, caption = "Network ID:"},
      {type = "textfield", width = 50, caption = "-1"},
      {type = "label", style = "subheader_caption_label", right_margin = 8, caption = "Surface:"},
      {type = "drop-down", items = {"(all)", "nauvis"}, selected_index = 2}
    }}
  )
end

return component