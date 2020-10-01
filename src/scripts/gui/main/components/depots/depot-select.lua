local gui = require("__flib__.gui-new")

local component = require("lib.gui-component")()

local function status_icon(color, value, ref)
  return (
    {type = "flow", vertical_align = "center", ref = ref, children = {
      {type = "sprite", style = "ltnm_status_icon", sprite = "ltnm_indicator_"..color},
      {type = "label", style = "ltnm_black_label", caption = value}
    }}
  )
end

function component.update(player, player_table, state, refs, handlers, msg, e)
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

        local child = children[index]
        if child then
          -- update
          local btn_refs = button_refs[index]

          btn_refs.depot_name.caption = depot_name
          btn_refs.trains.caption = available_trains_count.." / "..depot_data.num_trains
          btn_refs.network_id.caption = depot_data.network_id

          local status_flow = btn_refs.status_flow
          local status_children = status_flow.children
          local status_index = 0
          for name, count in pairs(statuses) do
            status_index = status_index + 1
            local icon_flow = status_children[status_index]
            if icon_flow then
              icon_flow.children[1].sprite = "ltnm_indicator_"..name
              icon_flow.children[2].caption = count
            else
              gui.build(status_flow, nil, {status_icon(name, count)})
            end
          end
          for i = status_index + 1, #status_children do
            status_children[i].destroy()
          end

          -- update button handler
          gui.add_handler(
            player.index,
            btn_refs.button.index,
            defines.events.on_gui_click,
            {tab = "depots", comp = "depot_select", action = "update_selected_depot", depot = depot_name},
            "main"
          )
        else
          -- create
          local status_elems = {}
          local status_elems_index = 0
          for status_name, status_count in pairs(statuses) do
            status_elems_index = status_elems_index + 1
            status_elems[#status_elems+1] = status_icon(status_name, status_count, {"statuses", status_elems_index})
          end
          local btn_refs, btn_handlers = gui.build(scroll_pane, "main", {
            {
              type = "button",
              style = "ltnm_depot_button",
              enabled = not is_selected_depot,
              on_click = {tab = "depots", comp = "depot_select", action = "update_selected_depot", depot = depot_name},
              ref = "button",
              children = {
                {
                  type = "flow",
                  style = "ltnm_depot_button_inner_flow",
                  direction = "vertical",
                  ignored_by_interaction = true,
                  children = {
                    {type = "label", style ="ltnm_bold_black_label", caption = depot_name, ref = "depot_name"},
                    {type = "flow", children = {
                      {type = "label", style = "ltnm_semibold_black_label", caption = {"ltnm-gui.trains-label"}},
                      {
                        type = "label",
                        style = "ltnm_black_label",
                        caption = available_trains_count.." / "..depot_data.num_trains,
                        ref = "trains"
                      }
                    }},
                    {type = "flow", children = {
                      {type = "label", style = "ltnm_semibold_black_label", caption = {"ltnm-gui.status-label"}},
                      {type = "flow", ref = "status_flow", children = status_elems}
                    }},
                    {type = "flow", children = {
                      {type = "label", style = "ltnm_semibold_black_label", caption = {"ltnm-gui.network-id-label"}},
                      {type = "label", style = "ltnm_black_label", caption = depot_data.network_id, ref = "network_id"}
                    }
                  }
                }}
              }
            }
          })
          button_refs[index] = btn_refs
          button_handlers[index] = btn_handlers
        end
      end
    end

    for i = index + 1, #children do
      local child = children[i]
      gui.remove_handler(player.index, child.index)
      child.destroy()
    end
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
          ref = {"depots", "depot_select", "scroll_pane"}
        }
      }
    }
  )
end

return component