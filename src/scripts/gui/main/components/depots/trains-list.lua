local gui = require("__flib__.gui-beta")

local constants = require("constants")

local util = require("scripts.util")

local sort_checkbox = require("scripts.gui.main.components.common.sort-checkbox")
local train_row = require("scripts.gui.main.components.depots.train-row")

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
  local scroll_pane = refs.depots.trains_list_scroll_pane

  util.gui_list(
    scroll_pane,
    {util.sorted_iterator(train_ids, trains, state.depots["sort_"..selected_sort])},
    function(train_data)
      return search_surface == -1 or search_surface == train_data.main_locomotive.surface.index
    end,
    train_row.build,
    train_row.update,
    constants.gui[player_table.translations.gui.locale_identifier].trains_list,
    player.index,
    player_table.translations
  )
end

return component