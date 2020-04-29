local stations_gui = {}

local gui = require("__flib__.control.gui")

local string_find = string.find
local string_gsub = string.gsub

local ltn_virtual_signals = {
  ["ltn-depot"] = true,
  ["ltn-depot-priority"] = true,
  ["ltn-network-id"] = true,
  ["ltn-min-train-length"] = true,
  ["ltn-max-train-length"] = true,
  ["ltn-max-trains"] = true,
  ["ltn-provider-threshold"] = true,
  ["ltn-provider-stack-threshold"] = true,
  ["ltn-provider-priority"] = true,
  ["ltn-locked-slots"] = true,
  ["ltn-requester-threshold"] = true,
  ["ltn-requester-stack-threshold"] = true,
  ["ltn-requester-priority"] = true,
  ["ltn-disable-warnings"] = true
}

gui.add_handlers{
  stations = {
    sort_checkbox = {
      on_gui_checked_state_changed = function(e)
        local _,_,clicked_type = string_find(e.element.name, "^ltnm_sort_station_(.-)$")
        local player_table = global.players[e.player_index]
        local gui_data = player_table.gui.main.stations
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
        UPDATE_MAIN_GUI(game.get_player(e.player_index), player_table, {stations_list=true})
      end
    }
  }
}

function stations_gui.update(player, player_table, state_changes, gui_data, data, material_translations)
  if state_changes.stations_list then
    local stations_table = gui_data.stations.table
    stations_table.clear()

    local trains = data.trains

    local active_sort = gui_data.stations.active_sort
    local sort_value = gui_data.stations["sort_"..active_sort]
    local stations = data.stations
    local sorted_stations = data.sorted_stations[active_sort]
    local start = sort_value and 1 or #sorted_stations
    local finish = sort_value and #sorted_stations or 1
    local delta = sort_value and 1 or -1
    for i=start,finish,delta do
      local station_id = sorted_stations[i]
      local t = stations[station_id]
      -- build GUI structure
      local elems = gui.build(stations_table, {
        {type="label", name="ltnm_view_station_"..sorted_stations[i], style="hoverable_bold_label", style_mods={horizontally_stretchable=true},
          caption=t.entity.backer_name, tooltip={"ltnm-gui.view-station-on-map"}},
        {type="label", style_mods={horizontal_align="center", width=24}, caption=t.network_id},
        gui.templates.status_indicator("indicator", t.status.name, t.status.count),
        -- items
        {type="frame", style="ltnm_dark_content_frame_in_light_frame", save_as="provided_requested_frame", children={
          {type="scroll-pane", style="ltnm_station_provided_requested_slot_table_scroll_pane", save_as="provided_requested_scroll_pane", children={
            {type="table", style="ltnm_small_slot_table", column_count=5, save_as="provided_requested_table"}
          }}
        }},
        {type="frame", style="ltnm_dark_content_frame_in_light_frame", save_as="shipments_frame", children={
          {type="scroll-pane", style="ltnm_station_shipments_slot_table_scroll_pane", save_as="shipments_scroll_pane", children={
            {type="table", style="ltnm_small_slot_table", column_count=4, save_as="shipments_table"}
          }}
        }},
        -- control signals
        {type="frame", style="ltnm_dark_content_frame_in_light_frame", save_as="signals_frame", children={
          {type="scroll-pane", style="ltnm_station_shipments_slot_table_scroll_pane", save_as="signals_scroll_pane", children={
            {type="table", style="ltnm_small_slot_table", column_count=4, save_as="signals_table"}
          }}
        }}
      })

      -- add provided/requested materials
      local table_add = elems.provided_requested_table.add
      local provided_requested_rows = 0
      local mi = 0
      for key, color in pairs{provided="green", requested="red"} do
        local materials = t[key]
        if materials then
          for name, count in pairs(materials) do
            mi = mi + 1
            provided_requested_rows = provided_requested_rows + 1
            table_add{type="sprite-button", name="ltnm_material_button_"..mi, style="ltnm_small_slot_button_"..color, sprite=string_gsub(name, ",", "/"),
              number=count, tooltip=(material_translations[name] or name).."\n"..util.comma_value(count)}
          end
        end
      end
      provided_requested_rows = math.ceil(provided_requested_rows / 6) -- number of rows

      -- add active shipments
      local shipments = t.active_deliveries
      local shipments_len = #shipments
      local shipments_rows = 0
      if shipments_len > 0 then
        table_add = elems.shipments_table.add
        mi = 0
        for si=1,#shipments do
          local train = trains[shipments[si]]
          local shipment = train.shipment
          local style = (train.from_id == station_id and "red" or "green")
          for name, count in pairs(shipment) do
            mi = mi + 1
            shipments_rows = shipments_rows + 1
            table_add{type="sprite-button", name="ltnm_material_button_"..mi, style="ltnm_small_slot_button_"..style, sprite=string_gsub(name, ",", "/"),
              number=count, tooltip=(material_translations[name] or name).."\n"..util.comma_value(count)}
          end
        end
        shipments_rows = math.ceil(shipments_rows / 4) -- number of rows
      else
        shipments_rows = 0
      end

      -- add control signals
      local signals = t.input.get_merged_signals()
      table_add = elems.signals_table.add
      local signals_rows = 0
      for si=1,#signals do
        local signal = signals[si]
        local name = signal.signal.name
        if ltn_virtual_signals[name] then
          signals_rows = signals_rows + 1
          table_add{type="sprite-button", style="ltnm_small_slot_button_dark_grey", sprite="virtual-signal/"..name, number=signal.count,
            tooltip={"", {"virtual-signal-name."..name}, "\n"..util.comma_value(signal.count)}}.enabled = false
        end
      end
      signals_rows = math.ceil(signals_rows / 4) -- number of rows

      local num_rows = math.max(provided_requested_rows, shipments_rows, signals_rows)

      -- set scroll pane properties
      if provided_requested_rows > 3 then
        elems.provided_requested_frame.style.right_margin = -12
        elems.shipments_frame.style = "ltnm_dark_content_frame_in_light_frame_no_left"
      end
      if shipments_rows > 3 then
        elems.shipments_frame.style.right_margin = -12
        elems.signals_frame.style = "ltnm_dark_content_frame_in_light_frame_no_left"
      end
      if shipments_rows > 3 then
        elems.shipments_frame.style.right_margin = -12
      end
      if num_rows > 1 then
        local frame_height = 36 * math.min(num_rows, 3)
        elems.provided_requested_scroll_pane.style.height = frame_height
        elems.shipments_scroll_pane.style.height = frame_height
        elems.signals_scroll_pane.style.height = frame_height
      end
    end
  end
end

stations_gui.base_template = {type="frame", style="ltnm_light_content_frame", direction="vertical", mods={visible=false},
  save_as="tabbed_pane.contents.stations", children={
    -- toolbar
    {type="frame", style="ltnm_toolbar_frame", children={
      {type="empty-widget", style_mods={height=28}},
      {type="checkbox", name="ltnm_sort_station_name", style="ltnm_sort_checkbox_active", style_mods={left_margin=-4}, caption={"ltnm-gui.station-name"},
        state=true, handlers="stations.sort_checkbox", save_as="stations.name_sort_checkbox"},
      {template="pushers.horizontal"},
      {type="checkbox", name="ltnm_sort_station_network_id", style="ltnm_sort_checkbox_inactive", style_mods={width=24},
        state=true, caption={"ltnm-gui.id"}, tooltip={"ltnm-gui.station-network-id-tooltip"}, handlers="stations.sort_checkbox",
        save_as="stations.network_id_sort_checkbox"},
      {type="flow", style_mods={horizontal_align="center", width=34}, children={
        {type="checkbox", name="ltnm_sort_station_status", style="ltnm_sort_checkbox_inactive", style_mods={width=8, height=20},
          tooltip={"ltnm-gui.station-status-tooltip"}, state=true, handlers="stations.sort_checkbox", save_as="stations.status_sort_checkbox"},
      }},
      {type="label", style="caption_label", style_mods={width=180}, caption={"ltnm-gui.provided-requested"},
        tooltip={"ltnm-gui.station-provided-requested-tooltip"}},
      {type="label", style="caption_label", style_mods={width=144}, caption={"ltnm-gui.shipments"}, tooltip={"ltnm-gui.station-shipments-tooltip"}},
      {type="label", style="caption_label", style_mods={width=144}, caption={"ltnm-gui.control-signals"}, tooltip={"ltnm-gui.station-control-signals-tooltip"}},
      {type="empty-widget", style_mods={width=8}}
    }},
    {type="scroll-pane", style="ltnm_blank_scroll_pane", direction="vertical", vertical_scroll_policy="always", save_as="stations.scroll_pane", children={
      {type="table", style="ltnm_stations_table", style_mods={vertically_stretchable=true, horizontally_stretchable=true}, column_count=6,
        save_as="stations.table"}
    }}
  }
}

return stations_gui