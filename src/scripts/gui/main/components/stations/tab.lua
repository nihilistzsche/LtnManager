local sort_checkbox = require("scripts.gui.main.components.common.sort-checkbox")
local status_indicator = require("scripts.gui.main.components.common.status-indicator")

local component = {}

function component.init()
  return {
    selected_sort = "station_name",
    sort_station_name = true,
    sort_status = true,
    sort_network_id = true
  }
end

function component.update()

end

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

local function mock_frame(state)
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

function component.view(state)
  local gui_constants = state.constants.stations_list
  local stations_state = state.stations
  local station_name_checkbox = sort_checkbox(
    "stations_list",
    "station_name",
    "station-name",
    nil,
    stations_state,
    gui_constants
  )
  station_name_checkbox.horizontally_stretchable = true
  return (
    {
      tab = {type = "tab", caption = {"ltnm-gui.stations"}},
      content = (
        {type = "frame", style = "deep_frame_in_shallow_frame", direction = "vertical", children = {
          {type = "frame", style = "ltnm_table_toolbar_frame", children = {
            station_name_checkbox,
            sort_checkbox(
              "stations_list",
              "status",
              "status",
              "station-status",
              stations_state,
              gui_constants
            ),
            sort_checkbox(
              "stations_list",
              "network_id",
              "network-id",
              "station-network-id",
              stations_state,
              gui_constants
            ),
            {
              type = "label",
              style = "caption_label",
              width = gui_constants.provided_requested,
              caption = {"ltnm-gui.provided-requested"},
              tooltip = {"ltnm-gui.provided-requested-tooltip"},
            },
            {
              type = "label",
              style = "caption_label",
              width = gui_constants.shipments,
              caption = {"ltnm-gui.shipments"},
              tooltip = {"ltnm-gui.shipments-tooltip"},
            },
            {
              type = "label",
              style = "caption_label",
              width = gui_constants.control_signals,
              caption = {"ltnm-gui.control-signals"},
              tooltip = {"ltnm-gui.control-signals-tooltip"},
            }
          }},
          {type = "scroll-pane", style = "ltnm_table_scroll_pane", children = {mock_frame(state)}}
        }}
      )
    }
  )
end

return component