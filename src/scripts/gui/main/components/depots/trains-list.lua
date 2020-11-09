local gui = require("__flib__.gui-beta")

local util = require("scripts.util")

local sort_checkbox = require("scripts.gui.main.components.common.sort-checkbox")
-- local train_row = require("scripts.gui.main.components.depots.train-row")

local component = {}

function component.build(widths)
  -- local constants = state.constants.trains_list
  -- local depots_state = state.depots
  -- local selected_depot = depots_state.selected_depot

  -- local depot_data = state.ltn_data.depots[selected_depot]

  -- local train_rows = {}

  -- if
  --   selected_depot
  --   and bit32.btest(depot_data.network_id, state.search.network_id)
  --   and string.find(string.lower(selected_depot), state.search.query)
  -- then
  --   train_rows = generate_train_rows(state, depots_state, depot_data)
  -- end

  return (
    {
      type = "frame",
      style = "deep_frame_in_shallow_frame",
      direction = "vertical",
      children = {
        {type = "frame", style = "ltnm_table_toolbar_frame", children = {
          sort_checkbox.build(widths.trains_list, "trains_list", "composition", "composition", "composition"),
          sort_checkbox.build(widths.trains_list, "trains_list", "status", "train-status", "train-status"),
          sort_checkbox.build(widths.trains_list, "trains_list", "shipment", "shipment")
        }},
        {type = "scroll-pane", style = "ltnm_table_scroll_pane", ref = {"depots", "trains_list_scroll_pane"}}
      }
    }
  )
end

function component.init()
  return {
    selected_sort = "composition",
    sort_composition = true,
    sort_status = true,
    sort_shipment = false
  }
end

function component.update(player, player_table, state, refs)
  local selected_depot = state.depots.selected_depot
  -- do nothing if no depot is selected
  if not selected_depot then return end

  local ltn_data = state.ltn_data
  local trains = ltn_data.trains
  local depot_data = ltn_data.depots[selected_depot]

  if not depot_data then return end -- shouldn't be needed, but just in case

  local selected_sort = state.depots.selected_sort
  local train_ids
  if selected_sort == "status" then
    train_ids = depot_data.sorted_trains.status[state.player_index]
  else
    train_ids = depot_data.sorted_trains[selected_sort]
  end

  local search_surface = state.search.surface
  local scroll_pane = refs.depots.trains_list

--   util.gui_list(
--     scroll_pane,
--     util.sorted_iterator(train_ids, trains, state.depots["sort_"..selected_sort]),
--     function(train_data)
--       return search_surface == -1 or search_surface == train_data.main_locomotive.surface.index
--     end
--   )
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
      -- train_rows[index] = train_row(state, train_id, train_data, train_status)
    end
  end

  return train_rows
end

return component