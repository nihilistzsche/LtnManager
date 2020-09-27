local component = require("lib.gui-component")()

component.template = (
  {type = "frame", style = "subheader_frame", style_mods = {bottom_margin = 12}, children = {
    {type = "textfield", lose_focus_on_confirm = true, clear_and_focus_on_right_click = true, text = ""},
    -- {type = "label", caption = "TODO: search funcs"},
    {type = "empty-widget", style = "flib_horizontal_pusher"},
    {type = "label", style = "subheader_caption_label", caption = "Surface:"},
    {type = "drop-down", items = {"(all)", "nauvis"}, selected_index = 2}
  }}
)

return component