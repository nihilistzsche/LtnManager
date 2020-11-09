local gui = require("__flib__.gui-beta")

local util = require("scripts.util")

local component = {}

function component.build(widths)
  return (
    {type = "frame", style = "ltnm_table_row_frame", horizontally_stretchable = true, children = {
      {
        type = "label",
        style = "ltnm_clickable_bold_label",
        style_mods = {width = widths.composition},
        tooltip = {"ltnm-gui.open-train-gui"},
        handlers = {on_click = "main_open_train_gui"}
      },
      {
        type = "flow",
        style = "ltnm_train_status_flow",
        -- horizontally_stretchable = true,
        style_mods = {width = widths.status},
        direction = "vertical"
      },
      {type = "frame", style = "ltnm_small_slot_table_frame", children = {
        {
          type = "table",
          style = "slot_table",
          width = (36 * 6),
          column_count = 6
        }
      }}
    }}
  )
end

function component.update()
  -- local status_elems
  -- if train_status.msg then
  --   status_elems = {
  --     {type = "label", style = "bold_label", font_color = train_status.color, caption = train_status.msg}
  --   }
  -- else
  --   status_elems = {
  --     {type = "label", style = "label", font_color = {255, 255, 255}, caption = train_status.type},
  --     {
  --       type = "label",
  --       style = "ltnm_clickable_bold_label",
  --       caption = train_data[train_status.station],
  --       tooltip = {"ltnm-gui.open-station-on-map"},
  --       on_click = {action = "open_station", station_id = train_data[train_status.station.."_id"]}
  --     }
  --   }
  -- end

  -- local shipment_elems = {}
  -- local index = 0
  -- for name, count in pairs(train_data.shipment or {}) do
  --   index = index + 1
  --   shipment_elems[index] = {
  --     type = "sprite-button",
  --     style = "ltnm_small_slot_button_default",
  --     sprite = string.gsub(name, ",", "/"),
  --     number = count,
  --     tooltip = util.material_button_tooltip(state.translations, name, count),
  --     enabled = false
  --   }
  -- end
end

return component
