local util = require("scripts.util")

local status_indicator = require("scripts.gui.main.components.common.status-indicator")

local component = {}

function component.build()
  return (
    {
      type = "button",
      style = "ltnm_depot_button",
      handlers = {
        on_click = "main_change_selected_depot",
      },
      children = {
        {
          type = "flow",
          -- TODO limit the width to clip long names
          style = "ltnm_depot_button_inner_flow",
          direction = "vertical",
          ignored_by_interaction = true,
          children = {
            {type = "label", style ="ltnm_bold_black_label"},
            {type = "flow", children = {
              {type = "label", style = "ltnm_semibold_black_label", caption = {"ltnm-gui.trains-label"}},
              {type = "label", style = "ltnm_black_label"}
            }},
            {type = "flow", children = {
              {type = "label", style = "ltnm_semibold_black_label", caption = {"ltnm-gui.status-label"}},
              {type = "flow"}
            }},
            {type = "flow", children = {
              {type = "label", style = "ltnm_semibold_black_label", caption = {"ltnm-gui.network-id-label"}},
              {type = "label", style = "ltnm_black_label"}
            }
          }
        }}
      }
    }
  )
end

function component.update(depot_data, depot_name, _, selected_depot)
  local is_selected = depot_name == selected_depot

  return (
    {elem_mods = {enabled = not is_selected}, children = {
      {children = {
        {elem_mods = {caption = depot_name}},
        {children = {
          {},
          {elem_mods = {caption = #depot_data.available_trains.." / "..depot_data.num_trains}}
        }},
        {children = {
          {},
          {
            cb = function(statuses_flow)
              util.gui_list(
                statuses_flow,
                {pairs(depot_data.statuses)},
                function() return true end,
                status_indicator.build_for_list,
                function(count, name)
                  return (
                    {children = {
                      {elem_mods = {sprite = "flib_indicator_"..name}},
                      {elem_mods = {caption = count}}
                    }}
                  )
                end
              )
            end
          }
        }},
        {children = {
          {},
          {elem_mods = {caption = tostring(depot_data.network_id)}}
        }}
      }}
    }}
  )
end

return component