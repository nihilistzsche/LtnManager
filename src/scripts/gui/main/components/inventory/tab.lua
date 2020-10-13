local gui = require("__flib__.gui3")

local component = gui.component()

function component.update() end

local function slot_table(caption, columns)
  return (
    {type = "frame", style = "deep_frame_in_shallow_frame", direction = "vertical", children = {
      {type = "frame", style = "subheader_frame", height = 32, width = (40 * columns), children = {
        {type = "label", style = "subheader_caption_label", caption = caption},
      }},
      {type = "scroll-pane", style = "ltnm_slot_table_scroll_pane", width = (40 * columns), height = (40 * 17)}
    }}
  )
end

function component.view(state)
  return (
    {
      tab = {type = "tab", caption = {"ltnm-gui.inventory"}},
      content = (
        {type = "flow", horizontal_spacing = 12, children = {
          slot_table("Provided", 13),
          slot_table("Requested", 7),
          slot_table("In transit", 7),
        }}
      )
    }
  )
end

return component