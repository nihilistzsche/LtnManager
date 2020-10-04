local gui = require("__flib__.gui-new")

local depot_button = require("scripts.gui.main.components.depots.depot-button")

local component = require("lib.gui-component")()

function component.update(player, _, state, refs, handlers, msg, e)
  -- ----- UPDATE -----
  if msg.update then
    -- LTN data
    local ltn_data = global.data
    local stations = ltn_data.stations
    -- GUI data
    local comp_refs = refs.depots.depot_select
    local button_refs = comp_refs.buttons
    local button_handlers = handlers.depots.depot_buttons
    local scroll_pane = comp_refs.scroll_pane
    local children = scroll_pane.children
    -- search queries
    local surface_query = state.search.surface
    local network_id_query = state.search.network_id

    local index = 0
    for depot_name, depot_data in pairs(ltn_data.depots) do
      index = index + 1
      -- TODO search depots by name
      -- match against surface and network ID
      if
        bit32.btest(depot_data.network_id, network_id_query)
        and (surface_query == -1 or depot_data.surfaces[surface_query])
      then
        -- if the selected depot does not exist, create it
        local selected_depot = state.depots.selected_depot
        if not selected_depot then
          state.depots.selected_depot = depot_name
          selected_depot = state.depots.selected_depot
        end
        local is_selected_depot = selected_depot == depot_name

        -- depot information
        local available_trains_count = #depot_data.available_trains
        -- TODO pre-process this information in ltn_data
        local statuses = {}
        for _, station_id in ipairs(depot_data.stations) do
          local station_data = stations[station_id]
          local status = station_data.status
          statuses[status.name] = (statuses[status.name] or 0) + status.count
        end

        -- create or update button
        local child = children[index]
        if child then
          -- update
          depot_button.update(
            button_refs[index],
            depot_data,
            is_selected_depot,
            depot_name,
            available_trains_count,
            statuses,
            player.index
          )
        else
          -- create
          local btn_refs, btn_handlers = gui.build(
            scroll_pane,
            "main",
            {
              depot_button.create(
                depot_data,
                is_selected_depot,
                depot_name,
                available_trains_count,
                statuses
              )
            }
          )
          button_refs[index] = btn_refs
          button_handlers[index] = btn_handlers
        end
      end
    end
    -- remove extraneous buttons
    for i = index + 1, #children do
      gui.remove_handlers(player.index, button_handlers[i])
      button_handlers[i] = nil
      children[i].destroy()
    end

  -- ----- UPDATE SELECTED -----
  elseif msg.action == "update_selected_depot" then
    local prev_depot= state.depots.selected_depot
    for _, button_refs in ipairs(refs.depots.depot_select.buttons) do
      local name_ref = button_refs.depot_name
      if name_ref.caption == prev_depot then
        button_refs.button.enabled = true
        break
      end
    end

    e.element.enabled = false
    state.depots.selected_depot = msg.depot
  end
end

function component.build()
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
          ref = {"depots", "depot_select", "scroll_pane"}
        }
      }
    }
  )
end

return component