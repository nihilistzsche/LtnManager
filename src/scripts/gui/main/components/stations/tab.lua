local gui = require("__flib__.gui3")

local sort_checkbox = require("scripts.gui.main.components.common.sort-checkbox")
local station_row = require("scripts.gui.main.components.stations.station-row")

local component = gui.component()

function component.init()
  return {
    selected_sort = "name",
    sort_name = true,
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

local function generate_station_rows(state, stations_state)
  local stations = state.ltn_data.stations

  -- get station IDs based on active sort
  local selected_sort = stations_state.selected_sort
  local station_ids = state.ltn_data.sorted_stations[selected_sort]
  local selected_sort_state = stations_state["sort_"..stations_state.selected_sort]

  -- search
  local search_state = state.search
  local search_query = search_state.query
  local search_network_id = search_state.network_id
  local search_surface = search_state.surface

  -- iteration data
  local start = selected_sort_state and 1 or #station_ids
  local finish = selected_sort_state and #station_ids or 1
  local step = selected_sort_state and 1 or -1

  -- build station rows
  local station_rows = {}
  local index = 0
  for i = start, finish, step do
    local station_id = station_ids[i]
    local station_data = stations[station_id]

    -- test against search queries
    if
      string.find(string.lower(station_data.name), search_query)
      -- TODO search against provided/requested and shipments
      and bit32.btest(station_data.network_id, search_network_id)
      and (search_surface == -1 or station_data.entity.surface.index == search_surface)
    then
      index = index + 1
      station_rows[index] = station_row(state, station_id, station_data)
    end
  end

  return station_rows
end

function component.view(state)
  local gui_constants = state.constants.stations_list
  local stations_state = state.stations

  local station_rows = generate_station_rows(state, stations_state)

  return (
    {
      tab = {type = "tab", caption = {"ltnm-gui.stations"}},
      content = (
        {type = "frame", style = "deep_frame_in_shallow_frame", direction = "vertical", children = {
          -- toolbar
          {type = "frame", style = "ltnm_table_toolbar_frame", children = {
            sort_checkbox(
              "stations_list",
              "name",
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
          -- content
          {type = "scroll-pane", style = "ltnm_table_scroll_pane", children = station_rows}
        }}
      )
    }
  )
end

return component