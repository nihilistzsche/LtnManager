local component = require("lib.gui-component")()

component.template = (
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

function component.update(player, player_table, gui_data)

end

return component