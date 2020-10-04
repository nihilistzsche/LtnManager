local gui = require("__flib__.gui-new")

local component = gui.component()

local function status_icon(color, value, ref)
  return (
    {type = "flow", vertical_align = "center", ref = ref, children = {
      {type = "sprite", style = "ltnm_status_icon", sprite = "ltnm_indicator_"..color},
      {type = "label", style = "ltnm_black_label", caption = value}
    }}
  )
end

function component.update(button_refs, depot_name, depot_data, is_selected_depot)
  button_refs.button.enabled = not is_selected_depot
  button_refs.depot_name.caption = depot_name
  button_refs.trains.caption = #depot_data.available_trains.." / "..depot_data.num_trains
  button_refs.network_id.caption = depot_data.network_id

  local status_flow = button_refs.status_flow
  local status_children = status_flow.children
  local status_index = 0
  for name, count in pairs(depot_data.statuses) do
    status_index = status_index + 1
    local icon_flow = status_children[status_index]
    if icon_flow then
      icon_flow.children[1].sprite = "ltnm_indicator_"..name
      icon_flow.children[2].caption = count
    else
      gui.build(status_flow, nil, {status_icon(name, count)})
    end
  end
  for i = status_index + 1, #status_children do
    status_children[i].destroy()
  end

  -- update button handler
  gui.add_handler(
    button_refs.button.player_index,
    button_refs.button.index,
    defines.events.on_gui_click,
    {tab = "depots", comp = "depot_select", action = "update_selected_depot", depot = depot_name},
    "main"
  )
end

function component.build()
  return (
    {
      type = "button",
      style = "ltnm_depot_button",
      -- placeholder on_click so it gets included in the handlers table
      on_click = {},
      ref = {"button"},
      children = {
        {
          type = "flow",
          -- TODO limit the width to clip long names
          style = "ltnm_depot_button_inner_flow",
          direction = "vertical",
          ignored_by_interaction = true,
          children = {
            {type = "label", style ="ltnm_bold_black_label", ref = {"depot_name"}},
            {type = "flow", children = {
              {type = "label", style = "ltnm_semibold_black_label", caption = {"ltnm-gui.trains-label"}},
              {
                type = "label",
                style = "ltnm_black_label",
                ref = {"trains"}
              }
            }},
            {type = "flow", children = {
              {type = "label", style = "ltnm_semibold_black_label", caption = {"ltnm-gui.status-label"}},
              {type = "flow", ref = {"status_flow"}}
            }},
            {type = "flow", children = {
              {type = "label", style = "ltnm_semibold_black_label", caption = {"ltnm-gui.network-id-label"}},
              {type = "label", style = "ltnm_black_label", ref = {"network_id"}}
            }
          }
        }}
      }
    }
  )
end

return component