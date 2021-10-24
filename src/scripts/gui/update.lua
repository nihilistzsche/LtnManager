local gui = require("__flib__.gui")

local constants = require("constants")

--- Updates the GUI based on the current set of LTN data.
return function(self)
  local widths = constants.gui[self.player_table.language] or constants.gui["en"]

  local state = self.state

  local search_query = state.search_query
  local search_network_id = state.network_id
  local search_surface = state.surface

  -- TEMPORARY:
  if state.active_tab == "trains" then
    local ltn_trains = global.data.trains
    local i = 0
    local scroll_pane = self.refs.trains.scroll_pane
    local children = scroll_pane.children
    for train_id, train_data in pairs(ltn_trains) do
      if train_data.train.valid and train_data.main_locomotive.valid then
        if
          (not search_surface or (train_data.main_locomotive.surface.index == search_surface))
          and bit32.btest(train_data.network_id, search_network_id)
          and (#search_query == 0 or string.find(train_data.search_strings[self.player.index], search_query))
        then
          i = i + 1
          local row = children[i]
          local color = i % 2 == 0 and "dark" or "light"
          if not row then
            row = gui.add(scroll_pane,
              {type = "frame", style = "ltnm_table_row_frame_"..color,
                {type = "frame", style = "ltnm_table_inset_frame_"..color,
                  {type = "minimap", style = "ltnm_train_minimap",
                    {type = "button", style = "ltnm_train_minimap_button", tooltip = {"gui.ltnm-open-train-gui"}},
                  },
                },
                {type = "label", style = "ltnm_clickable_bold_label"},
                {type = "frame", style = "ltnm_small_slot_table_frame_"..color,
                  {type = "sprite-button", style = "ltnm_small_slot_button_default"},
                },
                {type = "empty-widget", style = "flib_horizontal_pusher"},
              }
            )
          end

          local status = train_data.status[self.player.index]
          local station_id = status.station and train_data[status.station.."_id"] or nil

          gui.update(row,
            {style = "ltnm_table_row_frame_"..color,
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
            }
          )
        end
      end
    end

    for j = i + 1, #children do
      children[j].destroy()
    end
  end
end
