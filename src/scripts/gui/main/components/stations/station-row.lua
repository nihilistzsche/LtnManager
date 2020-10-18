local gui = require("__flib__.gui3")

local slot_table = require("scripts.gui.main.components.common.slot-table")
local status_indicator = require("scripts.gui.main.components.common.status-indicator")

local component = gui.component()

function component.view(state, station_id, station_data)
  local gui_constants = state.constants.stations_list
  local status = station_data.status
  local translations = state.translations

  return (
    {type = "frame", style = "ltnm_table_row_frame", horizontally_stretchable = true, children = {
      {
        type = "label",
        style = "ltnm_clickable_bold_label",
        width = gui_constants.name,
        caption = station_data.name,
        tooltip = {"ltnm-gui.open-station-on-map"},
        on_click = {action = "open_station", station_id = station_id},
      },
      status_indicator(status.color, status.count, nil, gui_constants.status),
      {
        type = "label",
        horizontal_align = "center",
        width = gui_constants.network_id,
        caption = station_data.network_id
      },
      slot_table(
        translations,
        gui_constants.provided_requested,
        {
          {color = "green", contents = station_data.provided, enabled = false, tooltip = "material"},
          {color = "red", contents = station_data.requested, enabled = false, tooltip = "material"}
        }
      ),
      slot_table(
        translations,
        gui_constants.shipments,
        {
          {color = "green", contents = station_data.inbound, enabled = false, tooltip = "material"},
          {color = "red", contents = station_data.outbound, enabled = false, tooltip = "material"}
        }
      ),
      slot_table(
        translations,
        gui_constants.control_signals,
        {
          {
            color = "default",
            contents = station_data.control_signals,
            enabled = false,
            sprite_class = "virtual-signal",
            tooltip = "ltn_control_signal"
          }
        }
      )
    }}
  )
end

return component