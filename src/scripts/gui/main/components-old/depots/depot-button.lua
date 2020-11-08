local gui = require("__flib__.gui-new")

local status_indicator = require("scripts.gui.main.components.common.status-indicator")

local component = gui.component()

function component.view(depot_name, depot_data, selected_depot)
  local statuses = {}
  local index = 0
  for name, count in pairs(depot_data.statuses) do
    index = index + 1
    statuses[index] = status_indicator(name, count, true)
  end

  return (
    {
      type = "button",
      style = "ltnm_depot_button",
      -- placeholder on_click so it gets included in the handlers table
      enabled = selected_depot ~= depot_name,
      on_click = {comp = "depot_select", action = "update_selected_depot", depot = depot_name},
      children = {
        {
          type = "flow",
          -- TODO limit the width to clip long names
          style = "ltnm_depot_button_inner_flow",
          direction = "vertical",
          ignored_by_interaction = true,
          children = {
            {type = "label", style ="ltnm_bold_black_label", caption = depot_name},
            {type = "flow", children = {
              {type = "label", style = "ltnm_semibold_black_label", caption = {"ltnm-gui.trains-label"}},
              {
                type = "label",
                style = "ltnm_black_label",
                caption = #depot_data.available_trains.." / "..depot_data.num_trains
              }
            }},
            {type = "flow", children = {
              {type = "label", style = "ltnm_semibold_black_label", caption = {"ltnm-gui.status-label"}},
              {type = "flow", children = statuses}
            }},
            {type = "flow", children = {
              {type = "label", style = "ltnm_semibold_black_label", caption = {"ltnm-gui.network-id-label"}},
              {type = "label", style = "ltnm_black_label", caption = tostring(depot_data.network_id)}
            }
          }
        }}
      }
    }
  )
end

return component