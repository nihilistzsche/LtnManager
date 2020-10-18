local gui = require("__flib__.gui3")
local misc = require("__flib__.misc")

local slot_table = require("scripts.gui.main.components.common.slot-table")

local component = gui.component()

function component.update()

end

function component.view(state, history_data)
  local widths = state.constants.history

  return (
    {type = "frame", style = "ltnm_table_row_frame", horizontally_stretchable = true, children = {
      {type = "label", width = widths.depot, caption = history_data.depot},
      {type = "label", horizontal_align = "center", width = widths.train_id, caption = history_data.train_id},
      {type = "label", horizontal_align = "center", width = widths.network_id, caption = history_data.network_id},
      {
        type = "flow",
        style = "ltnm_train_status_flow",
        width = widths.route,
        direction = "vertical",
        children = {
          {
            type = "label",
            style = "ltnm_clickable_bold_label",
            caption = history_data.from,
            tooltip = {"ltnm-gui.open-station-on-map"},
            on_click = {action = "open_station", station_id = history_data.from_id}
          },
          {type = "flow", children = {
            {type = "label", style = "caption_label", caption = "->"},
            {
              type = "label",
              style = "ltnm_clickable_bold_label",
              caption = history_data.to,
              tooltip = {"ltnm-gui.open-station-on-map"},
              on_click = {action = "open_station", station_id = history_data.to_id}
            }
          }}
        }
      },
      {
        type = "label",
        horizontal_align = "center",
        width = widths.runtime,
        caption = misc.ticks_to_timestring(history_data.runtime)
      },
      {
        type = "label",
        horizontal_align = "center",
        width = widths.finished,
        caption = misc.ticks_to_timestring(history_data.finished)
      },
      slot_table(
        state.translations,
        widths.shipment,
        {{color = "default", contents = history_data.shipment, enabled = false, tooltip = "material"}}
      )
    }}
  )
end

return component