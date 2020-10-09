local gui = require("__flib__.gui3")

local depot_button = require("scripts.gui.main.components.depots.depot-button")

local util = require("scripts.util")

local component = gui.component()

function component.update(msg, e)
  -- ----- UPDATE -----
  if msg.update then
    local player, _, state, refs, handlers = util.get_updater_properties(e.player_index)

    -- LTN data
    local ltn_data = global.data
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
      -- TODO search depots by name
      -- match against surface and network ID
      if
        bit32.btest(depot_data.network_id, network_id_query)
        and (surface_query == -1 or depot_data.surfaces[surface_query])
      then
        index = index + 1
        -- if the selected depot does not exist, create it
        local selected_depot = state.depots.selected_depot
        if not selected_depot then
          state.depots.selected_depot = depot_name
          selected_depot = state.depots.selected_depot
        end
        local is_selected_depot = selected_depot == depot_name

        if not children[index] then
          -- create button
          local btn_refs, btn_handlers = gui.build(scroll_pane, "main", {depot_button()})
          button_refs[index] = btn_refs
          button_handlers[index] = btn_handlers
        end
        -- update
        depot_button.update(
          button_refs[index],
          depot_name,
          depot_data,
          is_selected_depot
        )
      end
    end
    -- remove extraneous buttons
    -- TODO show blurred panel if search shows zero buttons
    for i = index + 1, #children do
      gui.remove_handlers(player.index, button_handlers[i])
      button_handlers[i] = nil
      children[i].destroy()
    end

  -- ----- UPDATE SELECTED -----
  elseif msg.action == "update_selected_depot" then
    local _, _, state, refs = util.get_updater_properties(e.player_index)

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

    gui.update("main", {tab = "depots", comp = "trains_list", action = "update"}, {player_index = e.player_index})
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