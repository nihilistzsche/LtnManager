local component = require("lib.gui-component")()

component.template = (
  {
    type = "frame",
    style = "deep_frame_in_shallow_frame",
    style_mods = {width = 206},
    handlers_prefix = "depot_select",
    save_as_prefix = "depot_select",
    children = {
      {type = "scroll-pane", style = "ltnm_depot_select_scroll_pane", children = {

      }}
    }
  }
)

function component.update(player, player_table, gui_data)

end

return component