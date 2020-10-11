local gui = require("__flib__.gui3")

local status_indicator = require("scripts.gui.main.components.common.status-indicator")
local util = require("scripts.util")

local tooltip_funcs = {
  ltn_control_signal = function(translations, name, count)
    return (
    "[img=virtual-signal/"
    ..name
    .."]  [font=default-bold]"
    ..translations.virtual_signals[name]
    .."[/font]"
    .."\n"
    .."[font=default-semibold]"
    ..translations.gui.count
    .."[/font] "
    ..util.comma_value(math.floor(count))
  )
  end,
  material = util.material_button_tooltip,
}

local component = gui.component()

local function slot_table(translations, width, contents)
  local columns = width / 36

  local buttons = {}
  local i = 0

  for _, data in pairs(contents) do
    if data.contents then
      local color = data.color
      local enabled = data.enabled
      local sprite_class = data.sprite_class
      local tooltip_func = tooltip_funcs[data.tooltip]
      local on_click = data.on_click
      for name, count in pairs(data.contents) do
        i = i + 1
        buttons[i] = {
          type = "sprite-button",
          style = "ltnm_small_slot_button_"..color,
          sprite = sprite_class and sprite_class.."/"..name or string.gsub(name, ",", "/"),
          number = count,
          tooltip = tooltip_func(translations, name, count),
          enabled = enabled,
          on_click = on_click or {action = "open_material", material = name}
        }
      end
    end
  end

  return (
    {
      type = "frame",
      style = "ltnm_small_slot_table_frame",
      children = {
        {type = "table", style = "slot_table", width = width, column_count = columns, children = buttons}
      }
    }
  )
end

function component.view(state, station_id, station_data)
  local gui_constants = state.constants.stations_list
  local status = station_data.status
  local translations = state.translations

  return (
    {type = "frame", style = "ltnm_table_row_frame", horizontally_stretchable = true, children = {
      {
        type = "label",
        style = "ltnm_clickable_bold_label",
        width = gui_constants.name,
        caption = station_data.name,
        tooltip = {"ltnm-gui.open-train-gui"},
        on_click = {action = "open_station", station_id = station_id},
      },
      status_indicator(status.color, status.count, nil, gui_constants.status),
      {
        type = "label",
        horizontal_align = "center",
        width = gui_constants.network_id,
        caption = station_data.network_id
      },
      slot_table(
        translations,
        gui_constants.provided_requested,
        {
          {color = "green", contents = station_data.provided, enabled = true, tooltip = "material"},
          {color = "red", contents = station_data.requested, enabled = true, tooltip = "material"}
        }
      ),
      slot_table(
        translations,
        gui_constants.shipments,
        {
          {color = "green", contents = station_data.inbound, enabled = true, tooltip = "material"},
          {color = "red", contents = station_data.outbound, enabled = true, tooltip = "material"}
        }
      ),
      slot_table(
        translations,
        gui_constants.control_signals,
        {
          {
            color = "default",
            contents = station_data.control_signals,
            enabled = false,
            sprite_class = "virtual-signal",
            tooltip = "ltn_control_signal"
          }
        }
      )
    }}
  )
end

return component