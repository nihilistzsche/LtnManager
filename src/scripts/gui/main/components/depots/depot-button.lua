local gui = require("__flib__.gui-beta")

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
      ref = {"button"},
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

function component.update(button, depot_name, depot_data, selected_depot)
  local is_selected = depot_name == selected_depot

  gui.update(button, (
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
              local children = statuses_flow.children
              local i = 0
              for name, count in pairs(depot_data.statuses) do
                i = i + 1
                local child = children[i]
                if not child then
                  child = gui.build(statuses_flow, {status_indicator.build(nil, true)}).flow
                end
                child.icon.sprite = "flib_indicator_"..name
                child.label.caption = count
              end
              for j = i + 1, #children do
                children[j].destroy()
              end
            end
          }
        }},
        {children = {
          {},
          {elem_mods = {caption = tostring(depot_data.network_id)}}
        }}
      }}
    }}
  ))
end

return component