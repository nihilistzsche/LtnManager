local gui = require("__flib__.gui-beta")

local util = require("scripts.util")

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

function component.update(_, _, state, refs)
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

  util.gui_list(
    scroll_pane,
    state.ltn_data.depots,
    function(depot_data, depot_name)
      if
        (surface_query == -1 or depot_data.surfaces[surface_query])
        and bit32.btest(depot_data.network_id, search_network_id)
        and string.find(string.lower(depot_name), search_query)
      then
        return true
      end
    end,
    depot_button.build,
    depot_button.update,
    selected_depot
  )
end

return component