local alerts_gui = {}

local gui = require("__flib__.control.gui")
local util = require("scripts.util")

local string_find = string.find
local string_gsub = string.gsub

gui.add_templates{
  alerts = {
    materials_table = function(parent, style, materials, material_translations)
      local table_add = gui.build(parent, {
        {type="frame", style="ltnm_dark_content_frame_in_light_frame", children={
          {type="scroll-pane", style="ltnm_train_slot_table_scroll_pane", children={
            {type="table", style="ltnm_small_slot_table", column_count=4, save_as="table"}
          }}
        }}
      }).table.add
      local mi = 0
      for name, count in pairs(materials) do
        mi = mi + 1
        table_add{type="sprite-button", name="ltnm_view_material__"..mi, style="ltnm_small_slot_button_"..style, sprite=string_gsub(name, ",", "/"),
          number=count, tooltip=(material_translations[name] or name).."\n"..util.comma_value(count)}
      end
    end
  }
}

gui.add_handlers{
  alerts = {
    sort_checkbox = {
      on_gui_checked_state_changed = function(e)
        local _,_,clicked_type = string_find(e.element.name, "^ltnm_sort_alerts_(.-)$")
        local player_table = global.players[e.player_index]
        local gui_data = player_table.gui.main.alerts
        if gui_data.active_sort ~= clicked_type then
          -- update styles
          gui_data[gui_data.active_sort.."_sort_checkbox"].style = "ltnm_sort_checkbox_inactive"
          e.element.style = "ltnm_sort_checkbox_active"
          -- reset the checkbox value and switch active sort
          e.element.state = not e.element.state
          gui_data.active_sort = clicked_type
        else
          -- update the state in global
          gui_data["sort_"..clicked_type] = e.element.state
        end
        -- update GUI contents
        alerts_gui.update(game.get_player(e.player_index), player_table, {alerts=true})
      end
    },
    clear_alert_button = {
      on_gui_click = {handler=function(e)
        local _,_,alert_id = string_find(e.element.name, "^ltnm_clear_alert_(.-)$")
        alert_id = tonumber(alert_id)
        global.data.alerts_to_delete[alert_id] = true
        alerts_gui.update(game.get_player(e.player_index), global.players[e.player_index], {alerts=true})
      end, gui_filters="ltnm_clear_alert_", options={match_filter_strings=true}}
    }
  }
}

function alerts_gui.update(player, player_table, state_changes, gui_data, data, material_translations)
  gui_data = gui_data or player_table.gui.main
  data = data or global.data
  material_translations = material_translations or player_table.dictionary["materials"].translations
  if state_changes.alerts then
    local alerts_table = gui_data.alerts.table
    alerts_table.clear()

    local active_sort = gui_data.alerts.active_sort
    local sort_value = gui_data.alerts["sort_"..active_sort]
    local sorted_alerts = data.sorted_alerts[active_sort]

    -- skip if there are no alerts
    if #sorted_alerts > 0 then
      local alerts = data.alerts
      local start = sort_value and 1 or #sorted_alerts
      local finish = sort_value and #sorted_alerts or 1
      local delta = sort_value and 1 or -1

      local to_be_deleted = global.data.alerts_to_delete

      for i=start,finish,delta do
        local alert_id = sorted_alerts[i]
        -- exclude if the alert is to be deleted
        if not to_be_deleted[alert_id] then
          local alert_data = alerts[alert_id]
          local elems = gui.build(alerts_table, {
            {type="label", style_mods={width=64}, caption=util.ticks_to_time(alert_data.time)},
            {type="label", style_mods={width=26, horizontal_align="center"}, caption=alert_data.train.network_id},
            {type="flow", style_mods={horizontally_stretchable=true, vertical_spacing=-1, top_padding=-2, bottom_padding=-1}, direction="vertical", children={
              {type="label", name="ltnm_view_station__"..alert_data.train.from_id, style="hoverable_bold_label", caption=alert_data.train.from,
                tooltip={"ltnm-gui.view-station-on-map"}},
              {type="flow", children={
                {type="label", style="caption_label", caption="->"},
                {type="label", name="ltnm_view_station__"..alert_data.train.to_id, style="hoverable_bold_label", caption=alert_data.train.to,
                  tooltip={"ltnm-gui.view-station-on-map"}}
              }}
            }},
            {type="label", style="bold_label", style_mods={width=160}, caption={"ltnm-gui.alert-"..alert_data.type},
              tooltip={"ltnm-gui.alert-"..alert_data.type.."-description"}},
            {type="flow", style_mods={vertical_spacing=8}, direction="vertical", save_as="tables_flow"},
            {type="flow", children={
              {type="frame", style="ltnm_dark_content_frame_in_light_frame", style_mods={padding=0}, children={
                {type="sprite-button", name="ltnm_open_train__"..alert_data.train.id, style="ltnm_inset_tool_button", sprite="utility/preset",
                  tooltip={"ltnm-gui.open-train-gui"}},
              }},
              {type="frame", style="ltnm_dark_content_frame_in_light_frame", style_mods={padding=0}, children={
                {type="sprite-button", name="ltnm_clear_alert_"..alert_id, style="ltnm_inset_red_icon_button", sprite="utility/trash",
                  tooltip={"ltnm-gui.clear-alert"}}
              }}
            }}
          })
          gui.templates.alerts.materials_table(elems.tables_flow, "green", alert_data.shipment or alert_data.planned_shipment, material_translations)
          if alert_data.actual_shipment or alert_data.leftovers then
            gui.templates.alerts.materials_table(elems.tables_flow, "red", alert_data.actual_shipment or alert_data.leftovers, material_translations)
          end
        end
      end
    end
  end
end

alerts_gui.base_template = {type="flow", style_mods={horizontal_spacing=12}, mods={visible=false}, save_as="tabbed_pane.contents.alerts", children={
  -- alerts list
  {type="frame", style="ltnm_light_content_frame", direction="vertical", children={
    {type="frame", style="ltnm_toolbar_frame", children={
      {type="checkbox", name="ltnm_sort_alerts_time", style="ltnm_sort_checkbox_active", style_mods={left_margin=8, width=64}, state=false,
        caption={"ltnm-gui.time"}, handlers="alerts.sort_checkbox", save_as="alerts.time_sort_checkbox"},
      {type="checkbox", name="ltnm_sort_alerts_network_id", style="ltnm_sort_checkbox_inactive", state=true, caption={"ltnm-gui.id"},
        tooltip={"ltnm-gui.history-network-id-tooltip"}, handlers="alerts.sort_checkbox", save_as="alerts.network_id_sort_checkbox"},
      {type="checkbox", name="ltnm_sort_alerts_route", style="ltnm_sort_checkbox_inactive", state=true, caption={"ltnm-gui.route"},
        handlers="alerts.sort_checkbox", save_as="alerts.route_sort_checkbox"},
      {template="pushers.horizontal"},
      {type="checkbox", name="ltnm_sort_alerts_type", style="ltnm_sort_checkbox_inactive", style_mods={width=160}, state=true,
        caption={"ltnm-gui.alert"}, handlers="alerts.sort_checkbox", save_as="alerts.type_sort_checkbox"},
      {type="empty-widget", style_mods={width=237, height=15}}
    }},
    {type="scroll-pane", style="ltnm_blank_scroll_pane", style_mods={vertically_stretchable=true, horizontally_stretchable=true},
      vertical_scroll_policy="always", children={
        {type="table", style="ltnm_rows_table", column_count=6, save_as="alerts.table"}
      }
    }
  }}
}}

return alerts_gui