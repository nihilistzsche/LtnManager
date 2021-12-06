local gui = require("__flib__.gui")

local constants = require("constants")
local util = require("scripts.util")

local templates = require("templates")

local trains_tab = {}

function trains_tab.build(widths)
  return {
    tab = {
      type = "tab",
      caption = { "gui.ltnm-trains" },
      ref = { "trains", "tab" },
      actions = {
        on_click = { gui = "main", action = "change_tab", tab = "trains" },
      },
    },
    content = {
      type = "frame",
      style = "ltnm_main_content_frame",
      direction = "vertical",
      ref = { "trains", "content_frame" },
      {
        type = "frame",
        style = "ltnm_table_toolbar_frame",
        templates.sort_checkbox(widths, "trains", "train_id", true),
        templates.sort_checkbox(widths, "trains", "status", false),
        templates.sort_checkbox(widths, "trains", "composition", false, { "gui.ltnm-composition-description" }),
        templates.sort_checkbox(widths, "trains", "depot", false),
        templates.sort_checkbox(widths, "trains", "shipment", false),
      },
      { type = "scroll-pane", style = "ltnm_table_scroll_pane", ref = { "trains", "scroll_pane" } },
      {
        type = "flow",
        style = "ltnm_warning_flow",
        visible = false,
        ref = { "trains", "warning_flow" },
        {
          type = "label",
          style = "ltnm_semibold_label",
          caption = { "gui.ltnm-no-trains" },
          ref = { "trains", "warning_label" },
        },
      },
    },
  }
end

function trains_tab.update(self)
  local dictionaries = self.player_table.dictionaries

  local state = self.state
  local refs = self.refs.trains
  local widths = self.widths

  local search_query = state.search_query
  local search_network_id = state.network_id
  local search_surface = state.surface

  local ltn_trains = state.ltn_data.trains
  local scroll_pane = refs.scroll_pane
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

    if train_data.train.valid and train_data.main_locomotive and train_data.main_locomotive.valid then
      if
        (search_surface == -1 or (train_data.surface_index == search_surface))
        and bit32.btest(train_data.network_id, search_network_id)
        and (
          #search_query == 0 or string.find(train_data.search_strings[self.player.index], string.lower(search_query))
        )
      then
        table_index = table_index + 1
        local row = children[table_index]
        local color = table_index % 2 == 0 and "dark" or "light"
        if not row then
          row = gui.add(scroll_pane, {
            type = "frame",
            style = "ltnm_table_row_frame_" .. color,
            {
              type = "frame",
              style = "ltnm_table_inset_frame_" .. color,
              {
                type = "minimap",
                style = "ltnm_train_minimap",
                { type = "label", style = "ltnm_minimap_label" },
                { type = "button", style = "ltnm_train_minimap_button", tooltip = { "gui.ltnm-open-train-gui" } },
              },
            },
            { type = "label", style = "ltnm_clickable_semibold_label" },
            { type = "label", style_mods = { width = widths.trains.composition } },
            { type = "label", style_mods = { width = widths.trains.depot } },
            {
              type = "frame",
              name = "shipment_frame",
              style = "ltnm_small_slot_table_frame_" .. color,
              style_mods = { width = widths.trains.shipment },
              {
                type = "table",
                name = "shipment_table",
                style = "slot_table",
                column_count = widths.trains.shipment_columns,
              },
            },
          })
        end

        local status = train_data.status[self.player.index]
        -- TODO: This shouldn't be needed any more
        if not status then
          status = { color = constants.colors.red.tbl, string = "ERROR" }
        end
        local station_id = status.station and train_data[status.station .. "_id"] or nil

        gui.update(row, {
          {
            {
              elem_mods = { entity = train_data.main_locomotive },
              { elem_mods = { caption = train_id } },
              {
                actions = {
                  on_click = { gui = "main", action = "open_train_gui", train_id = train_id },
                },
              },
            },
          },
          {
            actions = {
              on_click = station_id and { gui = "main", action = "open_station_gui", station_id = station_id } or false,
            },
            elem_mods = { caption = status.string, tooltip = station_id and constants.open_station_gui_tooltip or "" },
            style = station_id and "ltnm_clickable_semibold_label" or "ltnm_semibold_label",
            style_mods = { font_color = status.color or constants.colors.white.tbl, width = widths.trains.status },
          },
          { elem_mods = { caption = train_data.composition } },
          { elem_mods = { caption = train_data.depot } },
        })

        util.slot_table_update(
          row.shipment_frame.shipment_table,
          { { color = "default", entries = train_data.shipment, translations = dictionaries.materials } }
        )
      end
    end
  end

  for child_index = table_index + 1, #children do
    children[child_index].destroy()
  end

  if table_index == 0 then
    refs.warning_flow.visible = true
    scroll_pane.visible = false
    refs.content_frame.style = "ltnm_main_warning_frame"
  else
    refs.warning_flow.visible = false
    scroll_pane.visible = true
    refs.content_frame.style = "ltnm_main_content_frame"
  end
end

return trains_tab
