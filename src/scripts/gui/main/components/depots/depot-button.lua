local gui = require("__flib__.gui-new")

local component = {}

local function status_icon(color, value, ref)
  return (
    {type = "flow", vertical_align = "center", ref = ref, children = {
      {type = "sprite", style = "ltnm_status_icon", sprite = "ltnm_indicator_"..color},
      {type = "label", style = "ltnm_black_label", caption = value}
    }}
  )
end

function component.create(depot_data, is_selected_depot, depot_name, available_trains_count, statuses)
  local status_elems = {}
  local status_elems_index = 0
  for status_name, status_count in pairs(statuses) do
    status_elems_index = status_elems_index + 1
    status_elems[#status_elems+1] = status_icon(status_name, status_count, {"statuses", status_elems_index})
  end

  return (
    {
      type = "button",
      style = "ltnm_depot_button",
      enabled = not is_selected_depot,
      on_click = {tab = "depots", comp = "depot_select", action = "update_selected_depot", depot = depot_name},
      ref = {"button"},
      children = {
        {
          type = "flow",
          -- TODO limit the width to clip long names
          style = "ltnm_depot_button_inner_flow",
          direction = "vertical",
          ignored_by_interaction = true,
          children = {
            {type = "label", style ="ltnm_bold_black_label", caption = depot_name, ref = {"depot_name"}},
            {type = "flow", children = {
              {type = "label", style = "ltnm_semibold_black_label", caption = {"ltnm-gui.trains-label"}},
              {
                type = "label",
                style = "ltnm_black_label",
                caption = available_trains_count.." / "..depot_data.num_trains,
                ref = {"trains"}
              }
            }},
            {type = "flow", children = {
              {type = "label", style = "ltnm_semibold_black_label", caption = {"ltnm-gui.status-label"}},
              {type = "flow", ref = {"status_flow"}, children = status_elems}
            }},
            {type = "flow", children = {
              {type = "label", style = "ltnm_semibold_black_label", caption = {"ltnm-gui.network-id-label"}},
              {type = "label", style = "ltnm_black_label", caption = depot_data.network_id, ref = {"network_id"}}
            }
          }
        }}
      }
    }
  )
end

function component.update(
  button_refs,
  depot_data,
  is_selected_depot,
  depot_name,
  available_trains_count,
  statuses,
  player_index
)
  button_refs.button.enabled = not is_selected_depot
  button_refs.depot_name.caption = depot_name
  button_refs.trains.caption = available_trains_count.." / "..depot_data.num_trains
  button_refs.network_id.caption = depot_data.network_id

  local status_flow = button_refs.status_flow
  local status_children = status_flow.children
  local status_index = 0
  for name, count in pairs(statuses) do
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
    player_index,
    button_refs.button.index,
    defines.events.on_gui_click,
    {tab = "depots", comp = "depot_select", action = "update_selected_depot", depot = depot_name},
    "main"
  )
end

return component