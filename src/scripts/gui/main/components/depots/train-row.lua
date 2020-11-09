local gui = require("__flib__.gui-beta")

local util = require("scripts.util")

local component = {}

function component.build(widths)
  return (
    {type = "frame", style = "ltnm_table_row_frame", style_mods = {horizontally_stretchable = true}, children = {
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
        direction = "vertical",
        children = {
          {type = "label"},
          {
            type = "label",
            style = "ltnm_clickable_bold_label",
            tooltip = {"ltnm-gui.open-station-on-map"},
            handlers = {
              {on_click = "main_open_station_on_map"}
            }
          }
        }
      },
      {type = "frame", style = "ltnm_small_slot_table_frame", children = {
        {
          type = "table",
          style = "slot_table",
          style_mods = {
            width = (36 * 6),
          },
          column_count = 6
        }
      }}
    }}
  )
end

function component.update(train_data, _, _, _, player_index, translations)
  local train_status = train_data.status[player_index]
  local single_label = train_status.msg
  return (
    {children = {
      {elem_mods = {
        caption = train_data.composition
      }},
      {children = {
        {
          style_mods = {
            font_color = single_label and train_status.color or {255, 255, 255}
          },
          elem_mods = {
            caption = train_status.msg or train_status.type,
            style = single_label and "bold_label" or "label",
          }
        },
        {elem_mods = {
          caption = train_data[train_status.station],
          visible = not single_label
        }}
      }},
      {children = {
        {cb = function(shipment_table)
          util.gui_list(
            shipment_table,
            {pairs(train_data.shipment or {})},
            function() return true end,
            function()
              return {
                type = "sprite-button",
                style = "ltnm_small_slot_button_default",
                enabled = false
              }
            end,
            function(count, name)
              return {
                elem_mods = {
                  number = count,
                  sprite = string.gsub(name, ",", "/"),
                  tooltip = util.material_button_tooltip(translations, name, count)
                }
              }
            end
          )
        end}
      }}
    }}
  )
end

return component
