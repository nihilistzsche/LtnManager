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
        {type = "button", style = "ltnm_depot_button", enabled = false, children = {
          {type = "flow", style = "ltnm_depot_button_inner_flow", direction = "vertical", children = {
            {type = "label", style ="ltnm_bold_black_label", caption = "Depot"},
            {type = "flow", children = {
              {type = "label", style = "ltnm_semibold_black_label", caption = "Trains:"},
              {type = "label", style = "ltnm_black_label", caption = "0/5"}
            }},
            {type = "label", style = "ltnm_semibold_black_label", caption = "Status:"},
            {type = "label", style = "ltnm_semibold_black_label", caption = "Network ID:"},
          }}
        }},
      }}
    }
  }
)

return component