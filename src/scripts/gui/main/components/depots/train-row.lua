local gui = require("__flib__.gui-new")

local constants = require("constants")

local component = {}

function component.update(refs, train_id, train_data, train_status, player_index)
  -- composition
  local composition_label = refs.composition
  composition_label.caption = train_data.composition
  gui.add_handler(
    player_index,
    composition_label.index,
    defines.events.on_gui_click,
    {order = "open_train", train_id = train_id},
    "main"
  )

  -- status
  local status_refs = refs.status
  for _, element in pairs(status_refs) do element.visible = false end
  if train_status.n_a then
    status_refs.n_a.visible = true
  elseif train_status.parked_at_depot then
    status_refs.parked_at_depot.visible = true
  elseif train_status.returning_to_depot then
    status_refs.returning_to_depot.visible = true
  else
    -- type
    local type_label = status_refs.type
    type_label.caption = train_status.type
    type_label.visible = true

    -- station
    local station_label = status_refs.station
    station_label.caption = train_data[train_status.station]
    station_label.visible = true
    gui.add_handler(
      player_index,
      station_label.index,
      defines.events.on_gui_click,
      {order = "open_station", station_id = train_data[train_status.station.."_id"]},
      "main"
    )
  end

  -- contents
  local contents_table = refs.contents.table
  local children = contents_table.children
  local contents = train_data.shipment
  local contents_index = 0
  -- update or build children
  for name, count in pairs(contents or {}) do
    contents_index = contents_index + 1
    local child = children[contents_index]
    if child then
      child.sprite = string.gsub(name, ",", "/")
      child.number = count
    else
      -- TODO make clicking work
      contents_table.add{
        type = "sprite-button",
        name = "ltnm_material_button__"..contents_index,
        style = "ltnm_small_slot_button_default",
        sprite = string.gsub(name, ",", "/"),
        number = count
      }
    end
  end
  -- destroy extraneous children
  for i = contents_index + 1, #children do
    children[i].destroy()
  end
end

function component.build(player_locale)
  local gui_constants = constants.gui[player_locale].trains_list

  return (
    {
      type = "frame",
      style = "ltnm_table_row_frame",
      children = {
        {
          type = "label",
          style = "ltnm_clickable_bold_label",
          width = gui_constants.composition,
          tooltip = {"ltnm-gui.open-train-gui"},
          -- placeholder on_click to make it insert into the handlers table
          on_click = {},
          ref = {"composition"}
        },
        {
          type = "flow",
          style = "ltnm_train_status_flow",
          width = gui_constants.status,
          direction = "vertical",
          children = {
            {type = "label", ref = {"status", "type"}},
            -- placeholder on_click to make it insert into the handlers table
            {type = "label", style = "ltnm_clickable_bold_label", on_click = {}, ref = {"status", "station"}},
            {
              type = "label",
              style = "bold_label",
              caption = {"ltnm-gui.returning-to-depot"},
              ref = {"status", "returning_to_depot"}
            },
            {
              type = "label",
              style = "ltnm_bold_green_label",
              caption = {"ltnm-gui.parked-at-depot"},
              ref = {"status", "parked_at_depot"}
            },
            {
              type = "label",
              style = "ltnm_bold_red_label",
              caption = {"ltnm-gui.not-available"},
              ref = {"status", "n_a"}
            },
          }
        },
        {type = "frame", style = "deep_frame_in_shallow_frame", ref = {"contents", "frame"}, children = {
          {
            type = "scroll-pane",
            style = "ltnm_small_slot_table_scroll_pane",
            ref = {"contents", "scroll_pane"},
            children = {
              {type = "table", style = "slot_table", width = (36 * 5), column_count = 5, ref = {"contents", "table"}}
            }
          }
        }},
        {type = "empty-widget", left_margin = -12, horizontally_stretchable = true}
      }
    }
  )
end

return component
