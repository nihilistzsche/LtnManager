-- local train_row = require("scripts.gui.main.components.depots.train-row")

local component = {}

function component.init()
  return {
    active_sort = "composition",
    sort_composition = true,
    sort_status = true
  }
end

function component.update(state, msg, e)
  -- ----- SORT -----
  if msg.action == "update_sort" then
    local sort = msg.sort
    local depots_state = state.depots

    if depots_state.active_sort ~= sort then
      e.element.state = not e.element.state
    end

    depots_state.active_sort = sort
    depots_state["sort_"..sort] = e.element.state
  end

  -- ----- UPDATE -----
  -- if msg.action == "update_sort" or msg.update or msg.action == "update" then
  --   local player, player_table, state, refs, handlers = util.get_updater_properties(e.player_index)

  --   local selected_depot = state.depots.selected_depot
  --   local depot_data = global.data.depots[selected_depot]
  --   if not depot_data then return end

  --   -- train data
  --   local trains = global.data.trains

  --   -- states
  --   local depots_state = state.depots
  --   local search_state = state.search

  --   -- get train IDs based on active sort
  --   local active_sort = depots_state.active_sort
  --   local train_ids
  --   if active_sort == "composition" then
  --     train_ids = depot_data.sorted_trains.composition
  --   else
  --     train_ids = depot_data.sorted_trains.status[player.index]
  --   end
  --   local active_sort_state = depots_state["sort_"..active_sort]

  --   -- search
  --   local search_query = search_state.query
  --   local search_surface = search_state.surface

  --   -- refs
  --   local trains_list_refs = refs.depots.trains_list
  --   local scroll_pane = trains_list_refs.scroll_pane
  --   local children = scroll_pane.children
  --   local rows_refs = trains_list_refs.rows

  --   -- handlers
  --   local rows_handlers = handlers.depots.train_rows

  --   -- player locale
  --   local player_locale = player_table.translations.gui.locale_identifier

  --   -- iteration data
  --   local start = active_sort_state and 1 or #train_ids
  --   local finish = active_sort_state and #train_ids or 1
  --   local step = active_sort_state and 1 or -1

  --   -- build / update rows
  --   local train_index = 0
  --   for i = start, finish, step do
  --     local train_id = train_ids[i]
  --     local train_data = trains[train_id]
  --     local train_status = train_data.status[player.index]
  --     local search_comparator = active_sort == "composition" and train_data.composition or train_status.string

  --     -- test against search queries
  --     if
  --       string.find(string.lower(search_comparator), search_query)
  --       and (search_surface == -1 or train_data.main_locomotive.surface.index == search_surface)
  --     then
  --       train_index = train_index + 1

  --       -- build the component if it doesn't exist
  --       if not children[train_index] then
  --         local row_refs, row_handlers = gui.build(scroll_pane, "main", {train_row(player_locale)})
  --         rows_refs[train_index] = row_refs
  --         rows_handlers[train_index] = row_handlers
  --       end

  --       -- update the component's data
  --       train_row.update(
  --         rows_refs[train_index],
  --         train_id,
  --         train_data,
  --         train_status,
  --         player.index,
  --         player_table.translations
  --       )
  --     end
  --   end

  --   -- delete extraneous rows
  --   for j = train_index + 1, #children do
  --     gui.remove_handlers(player.index, rows_handlers[j])
  --     rows_handlers[j] = nil
  --     children[j].destroy()
  --   end
  -- end
end

local function sort_checkbox(sort_name, depots_state, constants, caption)
  return {
    type = "checkbox",
    style = depots_state.active_sort == sort_name and "ltnm_selected_sort_checkbox" or "ltnm_sort_checkbox",
    width = constants[sort_name],
    caption = {"ltnm-gui."..(caption or sort_name)},
    tooltip = {"ltnm-gui."..(caption or sort_name).."-tooltip"},
    state = depots_state["sort_"..sort_name],
    on_click = {comp = "trains_list", action = "update_sort", sort = sort_name},
  }
end

function component.view(state)
  local constants = state.constants.trains_list
  local depots_state = state.depots
  return (
    {
      type = "frame",
      style = "deep_frame_in_shallow_frame",
      direction = "vertical",
      children = {
        {type = "frame", style = "ltnm_table_toolbar_frame", children = {
          sort_checkbox("composition", depots_state, constants),
          sort_checkbox("status", depots_state, constants, "train-status"),
          -- TODO make train contents sortable and searchable
          {
            type = "label",
            style = "caption_label",
            width = constants.shipment,
            caption = {"ltnm-gui.shipment"},
            tooltip = {"ltnm-gui.shipment-tooltip"},
          }
        }},
        {type = "scroll-pane", style = "ltnm_table_scroll_pane"}
      }
    }
  )
end

return component