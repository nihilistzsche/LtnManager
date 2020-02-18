-- -------------------------------------------------------------------------------------------------------------------------------------------------------------
-- MAIN GUI
-- The main GUI for the mod

-- dependencies
local event = require('lualib/event')
local gui = require('lualib/gui')

-- self object
local self = {}

-- -----------------------------------------------------------------------------
-- GUI DATA

gui.add_templates{
  pushers = {
    horizontal = {type='empty-widget', style={horizontally_stretchable=true}},
    vertical = {type='empty-widget', style={vertically_stretchable=true}}
  }
}

-- -----------------------------------------------------------------------------
-- GUI MANAGEMENT

function self.create(player, player_table)
  local gui_data = gui.create(player.gui.screen, 'main', player.index,
    {type='frame', style='dialog_frame', direction='vertical', save_as='window', children={
      -- titlebar
      {type='flow', style='ltnm_titlebar_flow', direction='horizontal', children={
        {type='label', style='frame_title', caption={'mod-name.LtnManager'}},
        {type='empty-widget', style='ltnm_titlebar_drag_handle', save_as='drag_handle'}
      }},
      {type='frame', style='inside_deep_frame_for_tabs', children={
        {type='tabbed-pane', style='ltnm_tabbed_pane', children={
          -- depots tab
          {type='tab-and-content', tab={type='tab', caption={'ltnm-gui.depots'}}, content=
            {type='frame', style='ltnm_scroll_pane_frame', direction='vertical', children={
              {type='scroll-pane', style='ltnm_depots_scroll_pane', direction='vertical', children={
                {type='frame', style={name='ltnm_depot_frame', height=308, horizontally_stretchable=true}, direction='vertical', children={
                  {type='label', style='caption_label', caption='Depot'}
                }}
              }}
            }}
          },
          -- stations tab
          {type='tab-and-content', tab={type='tab', caption={'ltnm-gui.stations'}}, content=
            {type='frame', style='ltnm_scroll_pane_frame', direction='vertical', children={
              -- toolbar
              {type='frame', style='subheader_frame', direction='horizontal', children={
                {template='pushers.horizontal'},
                {type='sprite-button', style='tool_button', sprite='utility/search_icon'}
              }},
              {type='scroll-pane', style='ltnm_stations_scroll_pane', direction='vertical', save_as='stations_scroll_pane'}
            }}
          },
          -- inventory tab
          {type='tab-and-content', tab={type='tab', caption={'ltnm-gui.inventory'}}, content=
            {type='flow', direction='vertical', children={
              {type='label', style='caption_label', caption={'ltnm-gui.available'}},
              {type='frame', style={name='ltnm_icon_slot_table_frame', height=160}, children={
                {type='scroll-pane', style='ltnm_icon_slot_table_scroll_pane', vertical_scroll_policy='always', children={
                  {type='table', style='ltnm_icon_slot_table', column_count=10, save_as='inventory_available_table'}
                }},
              }},
              {type='label', style='caption_label', caption={'ltnm-gui.requested'}},
              {type='frame', style={name='ltnm_icon_slot_table_frame', height=160}, children={
                {type='scroll-pane', style='ltnm_icon_slot_table_scroll_pane', vertical_scroll_policy='always', children={
                  {type='table', style='ltnm_icon_slot_table', column_count=10, save_as='inventory_requested_table'}
                }},
              }},
              {type='label', style='caption_label', caption={'ltnm-gui.in-transit'}},
              {type='frame', style={name='ltnm_icon_slot_table_frame', height=160}, children={
                {type='scroll-pane', style='ltnm_icon_slot_table_scroll_pane', vertical_scroll_policy='always', children={
                  {type='table', style='ltnm_icon_slot_table', column_count=10, save_as='inventory_in_transit_table'}
                }},
              }}
            }}
          },
          -- history tab
          {type='tab-and-content', tab={type='tab', caption={'ltnm-gui.history'}, mods={enabled=false}}, content=
            {type='empty-widget'}
          },
          -- alerts tab
          {type='tab-and-content', tab={type='tab', caption={'ltnm-gui.alerts'}, mods={enabled=false}}, content=
            {type='empty-widget'}
          }
        }}
      }}
    }}
  )

  --
  -- TEMPORARY DATA INSERTION
  -- This will get separated out into a separate function later, this is just for prototyping GUI layouts
  --

  -- STATIONS
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
      local materials_table = frame.add{type='table', column_count=5}
      materials_table.style.left_padding = 4
      materials_table.style.horizontal_spacing = 2
      materials_table.style.vertical_spacing = 2
      materials_table.style.width = 172
      local i = 0
      if t.available then
        local materials = t.available
        for name,count in pairs(materials) do
          i = i + 1
          materials_table.add{type='sprite-button', style='ltnm_row_slot_button_green', sprite=string.gsub(name, ',', '/'), number=count}
        end
      end
      if t.requests then
        local materials = t.requests
        for name,count in pairs(materials) do
          i = i + 1
          materials_table.add{type='sprite-button', style='ltnm_row_slot_button_red', sprite=string.gsub(name, ',', '/'), number=-count}
        end
      end
      if i%5 ~= 0 or i == 0 then
        for _=1,5-(i%5) do
          materials_table.add{type='sprite-button', style='ltnm_row_slot_button_dark_grey'}
        end
      end
    end
  end

  --
  --
  --

  -- dragging and centering
  gui_data.drag_handle.drag_target = gui_data.window
  gui_data.window.force_auto_center()

  player_table.gui.main = gui_data
end

function self.destroy(player, player_table)
  gui.destroy(player_table.gui.main.window, 'main', player.index)
  player_table.gui.main = nil
end

return self