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
  local type_label = status_refs.type
  local station_label = status_refs.station
  local msg_label = status_refs.msg
  if train_status.msg then
    -- style
    type_label.visible = false
    station_label.visible = false
    msg_label.visible = true
    msg_label.style.font_color = train_status.color

    msg_label.caption = train_status.msg
  else
    -- style
    type_label.visible = true
    station_label.visible = true
    msg_label.visible = false

    -- type
    type_label.caption = train_status.type

    -- station
    station_label.caption = train_data[train_status.station]
    gui.add_handler(
      player_index,
      station_label.index,
      defines.events.on_gui_click,
      {order = "open_station", station_id = train_data[train_status.station.."_id"]},
      "main"
    )
  end

  -- shipment
  local shipment_table = refs.shipment.table
  local children = shipment_table.children
  local shipment = train_data.shipment
  local shipment_index = 0
  -- update or build children
  for name, count in pairs(shipment or {}) do
    shipment_index = shipment_index + 1
    local child = children[shipment_index]
    if child then
      child.sprite = string.gsub(name, ",", "/")
      child.number = count
    else
      -- TODO make clicking work
      shipment_table.add{
        type = "sprite-button",
        name = "ltnm_material_button__"..shipment_index,
        style = "ltnm_small_slot_button_default",
        sprite = string.gsub(name, ",", "/"),
        number = count
      }
    end
  end
  -- destroy extraneous children
  for i = shipment_index + 1, #children do
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
            {
              type = "label",
              style = "ltnm_clickable_bold_label",
              tooltip = {"ltnm-gui.open-station-on-map"},
              -- placeholder on_click to make it insert into the handlers table
              on_click = {},
              ref = {"status", "station"}
            },
            {type = "label", style = "bold_label", ref = {"status", "msg"}},
          }
        },
        {type = "frame", style = "deep_frame_in_shallow_frame", ref = {"shipment", "frame"}, children = {
          {
            type = "scroll-pane",
            style = "ltnm_small_slot_table_scroll_pane",
            ref = {"shipment", "scroll_pane"},
            children = {
              {type = "table", style = "slot_table", width = (36 * 5), column_count = 5, ref = {"shipment", "table"}}
            }
          }
        }},
        {type = "empty-widget", left_margin = -12, horizontally_stretchable = true}
      }
    }
  )
end

return component
