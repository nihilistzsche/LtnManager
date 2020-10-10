local component = {}

local sort_checkbox = require("scripts.gui.main.components.sort-checkbox")

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

function component.view(state)
  local gui_constants = state.constants.stations_list
  local stations_state = state.stations
  return (
    {
      tab = {type = "tab", caption = {"ltnm-gui.stations"}},
      content = (
        {type = "frame", style = "deep_frame_in_shallow_frame", direction = "vertical", children = {
          {type = "frame", style = "ltnm_table_toolbar_frame", children = {
            sort_checkbox(
              "stations_list",
              "station_name",
              "station-name",
              nil,
              stations_state,
              gui_constants
            ),
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
          {type = "scroll-pane", style = "ltnm_table_scroll_pane", vertically_stretchable = true}
        }}
      )
    }
  )
end

return component