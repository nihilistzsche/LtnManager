local gui = require("__flib__.gui-beta")

local depot_button = require("scripts.gui.main.components.depots.depot-button")

local component = {}

function component.build(widths)
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
          ref = {"depots", "depot_select"}
        }
      }
    }
  )
end

function component.init()
  return {} -- the default selected depot will be set in update()
end

function component.update(player, player_table, state, refs)
  -- set default selected depot
  if not state.depots.selected_depot then
    local first_depot = next(state.ltn_data.depots)
    if first_depot then
      state.depots.selected_depot = first_depot
    end
  end

  local surface_query = state.search.surface
  local search_query = state.search.query
  local search_network_id = state.search.network_id
  local selected_depot = state.depots.selected_depot

  local scroll_pane = refs.depots.depot_select
  local children = scroll_pane.children

  local i = 0
  for depot_name, depot_data in pairs(state.ltn_data.depots) do
    if
      (surface_query == -1 or depot_data.surfaces[surface_query])
      and bit32.btest(depot_data.network_id, search_network_id)
      and string.find(string.lower(depot_name), search_query)
    then
      i = i + 1
      local child = children[i]
      if not child then
        child = gui.build(scroll_pane, {depot_button.build()}).button
      end
      depot_button.update(child, depot_name, depot_data, selected_depot)
    end
  end
  for j = i + 1, #children do
    children[j].destroy()
  end
end

return component