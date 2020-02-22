-- -------------------------------------------------------------------------------------------------------------------------------------------------------------
-- MAIN GUI
-- The main GUI for the mod

-- dependencies
local event = require('lualib/event')
local gui = require('lualib/gui')
local util = require('scripts/util')

-- locals
local string_gsub = string.gsub

-- self object
local self = {}

-- -----------------------------------------------------------------------------
-- GUI DATA

gui.add_templates{
  pushers = {
    horizontal = {type='empty-widget', style={horizontally_stretchable=true}},
    vertical = {type='empty-widget', style={vertically_stretchable=true}}
  },
  inventory_slot_table_with_label = function(name)
    return {type='flow', direction='vertical', children={
      {type='label', style='caption_label', caption={'ltnm-gui.'..string_gsub(name, '_', '-')}},
      {type='frame', style='ltnm_icon_slot_table_frame', children={
        {type='scroll-pane', style='ltnm_icon_slot_table_scroll_pane', vertical_scroll_policy='always', children={
          {type='table', style='ltnm_icon_slot_table', column_count=8, save_as='inventory_'..name..'_table'}
        }}
      }}
    }}
  end
}

-- -----------------------------------------------------------------------------
-- GUI MANAGEMENT

function self.create(player, player_table)
  local gui_data = gui.create(player.gui.screen, 'main', player.index,
    {type='frame', style='ltnm_empty_frame', direction='vertical', save_as='window', children={
      {type='tabbed-pane', style='ltnm_tabbed_pane', children={
        -- depots tab
        {type='tab-and-content', tab={type='tab', style='ltnm_main_tab', caption={'ltnm-gui.depots'}}, content=
          {type='frame', style='ltnm_dark_content_frame', direction='vertical', children={
            {type='scroll-pane', style='ltnm_depots_scroll_pane', direction='vertical', children={
              {type='frame', style={name='ltnm_depot_frame', height=308, horizontally_stretchable=true}, direction='vertical', children={
                {type='label', style='caption_label', caption='Depot'}
              }}
            }}
          }}
        },
        -- stations tab
        {type='tab-and-content', tab={type='tab', style='ltnm_main_tab', caption={'ltnm-gui.stations'}}, content=
          {type='frame', style='ltnm_dark_content_frame', direction='vertical', children={
            -- toolbar
            {type='frame', style='subheader_frame', direction='vertical', children={
              {type='flow', direction='horizontal', children={
                {template='pushers.horizontal'},
                {type='sprite-button', style='tool_button', sprite='utility/search_icon'}
              }},
              {type='flow', style='ltnm_station_labels_flow', direction='horizontal', children={
                {type='label', style={name='bold_label', left_margin=4,width=220}, caption={'ltnm-gui.station-name'}},
                {type='label', style={name='bold_label', width=168}, caption={'ltnm-gui.inventory'}},
                {type='label', style={name='bold_label', width=134}, caption={'ltnm-gui.deliveries'}},
                -- {type='label', style={name='bold_label', width=}, caption={'ltnm-gui.station-'}},
              }}
            }},
            {type='scroll-pane', style='ltnm_stations_scroll_pane', direction='vertical', save_as='stations_scroll_pane'}
          }}
        },
        -- inventory tab
        {type='tab-and-content', tab={type='tab', style='ltnm_main_tab', caption={'ltnm-gui.inventory'}}, content=
          {type='frame', style='ltnm_light_content_frame', direction='vertical', children={
            -- toolbar
            {type='frame', style='subheader_frame', direction='horizontal', children={
              {type='empty-widget', style={height=24, horizontally_stretchable=true}}
            }},
            -- contents
            {type='flow', style={padding=10}, direction='vertical', children={
              gui.call_template('inventory_slot_table_with_label', 'available'),
              gui.call_template('inventory_slot_table_with_label', 'requested'),
              gui.call_template('inventory_slot_table_with_label', 'in_transit')
            }}
          }}
        },
        -- history tab
        {type='tab-and-content', tab={type='tab', style='ltnm_main_tab', caption={'ltnm-gui.history'}, mods={enabled=false}}, content=
          {type='empty-widget'}
        },
        -- alerts tab
        {type='tab-and-content', tab={type='tab', style='ltnm_main_tab', caption={'ltnm-gui.alerts'}, mods={enabled=false}}, content=
          {type='empty-widget'}
        }
      }}
    }}
  )

  --
  -- TEMPORARY DATA INSERTION
  -- This will get separated out into a separate function later, this is just for prototyping GUI layouts
  --

  -- STATIONS
  do
    local pane = gui_data.stations_scroll_pane
    local stations = global.data.stations
    for id,t in pairs(stations) do
      if not t.isDepot then
        -- get lamp color
        local color = t.lampControl.get_circuit_network(defines.wire_type.red).signals[1].signal.name
        local frame = pane.add{type='frame', style='ltnm_station_row_frame', direction='horizontal'}
        -- name
        local name_flow = frame.add{type='flow', direction='horizontal'}
        name_flow.style.vertical_align = 'center'
        name_flow.style.width = 220
        name_flow.style.vertically_stretchable = true
        name_flow.add{type='sprite', sprite='ltnm_indicator_'..color}.style.left_margin = 2
        name_flow.add{type='label', caption=t.entity.backer_name}.style.left_margin = 2
        -- items
        do
          local table = frame.add{type='table', column_count=5}
          table.style.horizontal_spacing = 2
          table.style.vertical_spacing = 2
          table.style.width = 168
          local i = 0
          if t.available then
            local materials = t.available
            for name,count in pairs(materials) do
              i = i + 1
              table.add{type='sprite-button', style='ltnm_row_slot_button_green', sprite=string_gsub(name, ',', '/'), number=count}
            end
          end
          if t.requests then
            local materials = t.requests
            for name,count in pairs(materials) do
              i = i + 1
              table.add{type='sprite-button', style='ltnm_row_slot_button_red', sprite=string_gsub(name, ',', '/'), number=-count}
            end
          end
          if i%5 ~= 0 or i == 0 then
            for _=1,5-(i%5) do
              table.add{type='sprite-button', style='ltnm_row_slot_button_dark_grey'}
            end
          end
        end
        -- active deliveries
        do
          local deliveries = global.data.deliveries
          local combined_shipment = {}
          for _,delivery_id in ipairs(t.activeDeliveries) do
            local delivery = deliveries[delivery_id]
            combined_shipment = util.add_materials(delivery.shipment, combined_shipment)
          end
          local table = frame.add{type='table', column_count=4}
          table.style.horizontal_spacing = 2
          table.style.vertical_spacing = 2
          table.style.width = 134
          local i = 0
          for name,count in pairs(combined_shipment) do
            i = i + 1
            table.add{type='sprite-button', style='ltnm_row_slot_button_dark_grey', sprite=string_gsub(name, ',', '/'), number=count}
          end
          if i%4 ~= 0 or i == 0 then
            for _=1,4-(i%4) do
              table.add{type='sprite-button', style='ltnm_row_slot_button_dark_grey'}
            end
          end
        end
      end
    end
  end

  -- INVENTORY
  local inventory = global.data.inventory
  for type,color in pairs{available='green', requested='red', in_transit='blue'} do
    -- combine materials
    local combined_materials = {}
    for _,materials in pairs(inventory[type]) do
      combined_materials = util.add_materials(materials, combined_materials)
    end
    -- add to table
    local table = gui_data['inventory_'..type..'_table']
    local add = table.add
    for name,count in pairs(combined_materials) do
      add{type='sprite-button', style='ltnm_slot_button_'..color, sprite=string_gsub(name, ',', '/'), number=count}
    end
  end

  --
  --
  --

  -- dragging and centering
  -- gui_data.drag_handle.drag_target = gui_data.window
  gui_data.window.force_auto_center()

  player_table.gui.main = gui_data
end

function self.destroy(player, player_table)
  gui.destroy(player_table.gui.main.window, 'main', player.index)
  player_table.gui.main = nil
end

return self