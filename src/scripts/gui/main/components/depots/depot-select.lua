local component = require("lib.gui-component")()

function component.build()
  return (
    {
      type = "frame",
      style = "deep_frame_in_shallow_frame",
      width = 206,
      children = {
        {type = "scroll-pane", style = "ltnm_depot_select_scroll_pane", children = {

        }}
      }
    }
  )
end

return component