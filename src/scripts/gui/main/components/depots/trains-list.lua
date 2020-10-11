local gui = require("__flib__.gui3")

local sort_checkbox = require("scripts.gui.main.components.common.sort-checkbox")
local train_row = require("scripts.gui.main.components.depots.train-row")

local component = gui.component()

function component.init()
  return {
    selected_sort = "composition",
    sort_composition = true,
    sort_status = true,
    sort_shipment = false
  }
end

function component.update(state, msg, e)
  if msg.action == "update_sort" then
    local sort = msg.sort
    local depots_state = state.depots

    if depots_state.selected_sort ~= sort then
      e.element.state = not e.element.state
    end

    depots_state.selected_sort = sort
    depots_state["sort_"..sort] = e.element.state
  end
end

local function generate_train_rows(state, depots_state, depot_data)
  local trains = state.ltn_data.trains

  -- get train IDs based on active sort
  local selected_sort = depots_state.selected_sort
  local train_ids
  if selected_sort == "status" then
    train_ids = depot_data.sorted_trains.status[state.player_index]
  else
    train_ids = depot_data.sorted_trains[selected_sort]
  end
  local selected_sort_state = depots_state["sort_"..depots_state.selected_sort]

  -- search
  local search_state = state.search
  local search_surface = search_state.surface

  -- iteration data
  local start = selected_sort_state and 1 or #train_ids
  local finish = selected_sort_state and #train_ids or 1
  local step = selected_sort_state and 1 or -1

  -- build train rows
  local train_rows = {}
  local index = 0
  for i = start, finish, step do
    local train_id = train_ids[i]
    local train_data = trains[train_id]
    local train_status = train_data.status[state.player_index]

    -- test against search queries
    if
      search_surface == -1 or train_data.main_locomotive.surface.index == search_surface
    then
      index = index + 1
      train_rows[index] = train_row(state, train_id, train_data, train_status)
    end
  end

  return train_rows
end

function component.view(state)
  local constants = state.constants.trains_list
  local depots_state = state.depots
  local selected_depot = depots_state.selected_depot

  local depot_data = state.ltn_data.depots[selected_depot]

  local train_rows = {}

  if
    selected_depot
    and string.find(selected_depot, state.search.query)
    and bit32.btest(depot_data.network_id, state.search.network_id)
  then
    train_rows = generate_train_rows(state, depots_state, depot_data)
  end

  return (
    {
      type = "frame",
      style = "deep_frame_in_shallow_frame",
      direction = "vertical",
      children = {
        {type = "frame", style = "ltnm_table_toolbar_frame", children = {
          sort_checkbox("trains_list", "composition", "composition", "composition", depots_state, constants),
          sort_checkbox("trains_list", "status", "train-status", "train-status", depots_state, constants),
          sort_checkbox("trains_list", "shipment", "shipment", "shipment", depots_state, constants)
        }},
        {type = "scroll-pane", style = "ltnm_table_scroll_pane", children = train_rows}
      }
    }
  )
end

return component