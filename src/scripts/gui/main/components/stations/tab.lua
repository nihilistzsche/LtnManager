local gui = require("__flib__.gui3")

local sort_checkbox = require("scripts.gui.main.components.common.sort-checkbox")
local status_indicator = require("scripts.gui.main.components.common.status-indicator")

local component = gui.component()

function component.init()
  return {
    selected_sort = "station_name",
    sort_station_name = true,
    sort_status = true,
    sort_network_id = true
  }
end

function component.update(state, msg, e)
  if msg.action == "update_sort" then
    local sort = msg.sort
    local stations_state = state.stations

    if stations_state.selected_sort ~= sort then
      e.element.state = not e.element.state
    end

    stations_state.selected_sort = sort
    stations_state["sort_"..sort] = e.element.state
  end
end

local function generate_station_rows(state, stations_state, gui_constants)

end

function component.view(state)
  local gui_constants = state.constants.stations_list
  local stations_state = state.stations

  local station_rows = generate_station_rows(state, stations_state, gui_constants)

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
          {type = "scroll-pane", style = "ltnm_table_scroll_pane", children = station_rows}
        }}
      )
    }
  )
end

return component