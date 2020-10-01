local component = require("lib.gui-component")()

function component.build()
  return {type = "button", style = "ltnm_depot_button", enabled = false, children = {
    {type = "flow", style = "ltnm_depot_button_inner_flow", direction = "vertical", children = {
      {type = "label", style ="ltnm_bold_black_label", caption = "Depot"},
      {type = "flow", children = {
        {type = "label", style = "ltnm_semibold_black_label", caption = "Trains:"},
        {type = "label", style = "ltnm_black_label", caption = "0/5"}
      }},
      {type = "label", style = "ltnm_semibold_black_label", caption = "Status:"},
      {type = "label", style = "ltnm_semibold_black_label", caption = "Network ID:"},
    }}
  }}
end

return component