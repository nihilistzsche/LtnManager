local gui = require("__flib__.gui3")

local component = gui.component()

local function slot_table(width)
  return (
    {type = "frame", style = "deep_frame_in_shallow_frame", width = (36 * width), children = {
      {
        type = "scroll-pane",
        style = "ltnm_small_slot_table_scroll_pane",
        children = {
          {type = "table", style = "slot_table", width = (36 * width), column_count = width}
        }
      }
    }}
  )
end

function component.view(station_data)
  local gui_constants = state.constants.stations_list
  return (
    {type = "frame", style = "ltnm_table_row_frame", horizontally_stretchable = true, children = {
      {
        type = "label",
        style = "ltnm_clickable_bold_label",
        width = gui_constants.station_name,
        caption = "Universal Logistics Station",
        tooltip = {"ltnm-gui.open-train-gui"},
        -- on_click = {action = "open_train", train_id = train_id},
      },
      status_indicator("signal-green", 1, nil, gui_constants.status),
      {type = "label", width = gui_constants.network_id, caption = "2333333333"},
      slot_table(6),
      slot_table(5),
      slot_table(7)
    }}
  )
end

return component