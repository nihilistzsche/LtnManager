local gui = require("__flib__.gui")
local misc = require("__flib__.misc")

local constants = require("constants")
local util = require("scripts.util")

local templates = require("templates")

local trains_tab = {}

function trains_tab.build(widths)
  return
    {tab = {type = "tab", caption = {"gui.ltnm-trains"}}, content =
      {
        type = "frame",
        style = "deep_frame_in_shallow_frame",
        style_mods = {height = 600},
        direction = "vertical",
        {type = "frame", style = "ltnm_table_toolbar_frame",
          {type = "empty-widget", style_mods = {width = widths.trains.minimap}},
          templates.sort_checkbox(
            widths,
            "trains",
            "status",
            true
          ),
          templates.sort_checkbox(
            widths,
            "trains",
            "composition",
            false
          ),
          templates.sort_checkbox(
            widths,
            "trains",
            "depot",
            false
          ),
          templates.sort_checkbox(
            widths,
            "trains",
            "shipment",
            false
          ),
          {type = "empty-widget", style = "flib_horizontal_pusher"},
        },
        {type = "scroll-pane", style = "ltnm_table_scroll_pane", ref = {"trains", "scroll_pane"}},
      },
    }
end

function trains_tab.update(self)
  local state = self.state
  local widths = self.widths

  local search_query = state.search_query
  local search_network_id = state.network_id
  local search_surface = state.surface

  local ltn_trains = state.ltn_data.trains
  local scroll_pane = self.refs.trains.scroll_pane
  local children = scroll_pane.children

  local sorts = state.sorts[state.active_tab]
  local active_sort = sorts._active
  local sorted_trains = state.ltn_data.sorted_trains[active_sort]
  if active_sort == "status" then
    sorted_trains = sorted_trains[self.player.index]
  end

  local table_index = 0

  -- False = ascending (arrow down), True = descending (arrow up)
  local start, finish, step
  if sorts[active_sort] then
    start = #sorted_trains
    finish = 1
    step = -1
  else
    start = 1
    finish = #sorted_trains
    step = 1
  end

  for sorted_index = start, finish, step do
    local train_id = sorted_trains[sorted_index]
    local train_data = ltn_trains[train_id]

    if train_data.train.valid and train_data.main_locomotive.valid then
      if
        (not search_surface or (train_data.main_locomotive.surface.index == search_surface))
        and bit32.btest(train_data.network_id, search_network_id)
        and (#search_query == 0 or string.find(train_data.search_strings[self.player.index], search_query))
      then
        table_index = table_index + 1
        local row = children[table_index]
        local color = table_index % 2 == 0 and "dark" or "light"
        if not row then
          row = gui.add(scroll_pane,
            {type = "frame", style = "ltnm_table_row_frame_"..color,
              {type = "frame", style = "ltnm_table_inset_frame_"..color,
                {type = "minimap", style = "ltnm_train_minimap",
                  {type = "button", style = "ltnm_train_minimap_button", tooltip = {"gui.ltnm-open-train-gui"}},
                },
              },
              {type = "label", style = "ltnm_clickable_bold_label"},
              {type = "label", style = "bold_label", style_mods = {width = widths.trains.composition}},
              {type = "label", style = "bold_label", style_mods = {width = widths.trains.depot}},
              {
                type = "frame",
                name = "shipment_frame",
                style = "ltnm_small_slot_table_frame_"..color,
                style_mods = {width = widths.trains.shipment},
                {type = "table", name = "shipment_table", style = "slot_table", column_count = 4},
              },
              {type = "empty-widget", style = "flib_horizontal_pusher"},
            }
          )
        end

        local status = train_data.status[self.player.index]
        -- TODO: This shouldn't be needed any more
        if not status then
          status = {color = constants.colors.red.tbl, string = "ERROR"}
        end
        local station_id = status.station and train_data[status.station.."_id"] or nil

        gui.update(row,
          {
            {
              {elem_mods = {entity = train_data.main_locomotive},
                {actions = {
                  on_click = {gui = "main", action = "open_train_gui", train_id = train_id},
                }},
              },
            },
            {
              actions = {
                on_click = station_id
                  and {gui = "main", action = "open_station_gui", station_id = station_id}
                  or false,
              },
              elem_mods = {caption = status.string, tooltip = station_id and {"gui.ltnm-open-station-gui"} or ""},
              style = station_id and "ltnm_clickable_bold_label" or "bold_label",
              style_mods = {font_color = status.color or constants.colors.white.tbl, width = widths.trains.status},
            },
            {elem_mods = {caption = train_data.composition}},
            {elem_mods = {caption = train_data.depot}},
          }
        )

        util.slot_table_update(row.shipment_frame.shipment_table, train_data.shipment, self.player_table.dictionaries)
      end
    end
  end

  for child_index = table_index + 1, #children do
    children[child_index].destroy()
  end
end

return trains_tab
