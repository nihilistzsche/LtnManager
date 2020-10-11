local gui = require("__flib__.gui3")

local depot_button = require("scripts.gui.main.components.depots.depot-button")

local component = gui.component()

function component.update(state, msg, e)
  if msg.action == "update_selected_depot" then
    state.depots.selected_depot = msg.depot
  end
end

function component.view(state)
  local surface_query = state.search.surface
  local search_query = state.search.query
  local search_network_id = state.search.network_id
  local selected_depot = state.depots.selected_depot

  -- build depot buttons
  local depot_buttons = {}
  local index = 0
  for depot_name, depot_data in pairs(state.ltn_data.depots) do
    if
      string.find(depot_name, search_query)
      and bit32.btest(depot_data.network_id, search_network_id)
      and (surface_query == -1 or depot_data.surfaces[surface_query])
    then
      index = index + 1
      depot_buttons[index] = depot_button(depot_name, depot_data, selected_depot)
    end
  end

  return (
    {
      type = "frame",
      style = "deep_frame_in_shallow_frame",
      width = 206,
      children = {
        {
          type = "scroll-pane",
          style = "ltnm_depot_select_scroll_pane",
          horizontal_scroll_policy = "never",
          children = depot_buttons
        }
      }
    }
  )
end

return component