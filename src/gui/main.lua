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
    vertical = {type='empty-widget', style={vertically_stretchable=true}},
    both = {type='empty-widget', style={horizontally_stretchable=true, vertically_stretchable=true}}
  },
  inventory_slot_table_with_label = function(name)
    return {type='flow', direction='vertical', children={
      {type='label', style='caption_label', caption={'ltnm-gui.'..string_gsub(name, '_', '-')}},
      {type='frame', style='ltnm_dark_content_frame_in_light_frame', children={
        {type='scroll-pane', style='ltnm_icon_slot_table_scroll_pane', vertical_scroll_policy='always', children={
          {type='table', style='ltnm_icon_slot_table', column_count=6, save_as='inventory_'..name..'_table'}
        }}
      }}
    }}
  end,
  close_button = {type='sprite-button', style='close_button', sprite='utility/close_white', hovered_sprite='utility/close_black',
    clicked_sprite='utility/close_black', save_as='close_button'},
  demo_station_contents = function()
    local elems = {}
    for i=1,20 do
      elems[#elems+1] = {type='sprite-button', style='ltnm_bordered_slot_button_green', sprite='item/poison-capsule', number=420000}
    end
    for i=21,24 do
      elems[#elems+1] = {type='sprite-button', style='ltnm_bordered_slot_button_red', sprite='item/poison-capsule', number=-6900}
    end
    return elems
  end,
  train_contents = function(num)
    local elems = {}
    for i=1,num do
      elems[#elems+1] = {type='sprite-button', style='ltnm_small_slot_button_dark_grey', sprite='item/poison-capsule', number=420000}
    end
    return elems
  end,
  depot_buttons = function()
    local children = {}
    -- selected
    children[1] = {type='button', style={name='ltnm_depot_button', height=85, padding=4, horizontally_stretchable=true}, children={
      {type='flow', direction='vertical', children={
        {type='label', style='caption_label', caption='Depot'},
        {type='flow', direction='horizontal', children={
          {type='label', style='bold_label', caption='Trains:'},
          {type='label', caption='1/5'}
        }},
        {type='flow', style={vertical_align='center', horizontal_spacing=6}, children={
          {type='label', style='bold_label', caption='Status:'},
          {type='flow', style={vertical_align='center'}, children={
            {type='sprite', sprite='ltnm_indicator_signal-blue'},
            {type='label', caption='2'}
          }},
          {type='flow', style={vertical_align='center'}, children={
            {type='sprite', sprite='ltnm_indicator_signal-green'},
            {type='label', caption='1'}
          }}
        }}
      }}
    }}
    -- unselected
    for i=2,4 do
      children[i] = {type='button', style={name='ltnm_depot_button', height=85, padding=4, horizontally_stretchable=true}, children={
        {type='flow', ignored_by_interaction=true, direction='vertical', children={
          {type='label', style={name='caption_label', font_color={28, 28, 28}}, caption='Depot'},
          {type='flow', direction='horizontal', children={
            {type='label', style={name='bold_label', font_color={28, 28, 28}}, caption='Trains:'},
            {type='label', style={font_color={}}, caption='1/5'}
          }},
          {type='flow', style={vertical_align='center', horizontal_spacing=6}, children={
            {type='label', style={name='bold_label', font_color={28, 28, 28}}, caption='Status:'},
            {type='flow', style={vertical_align='center'}, children={
              {type='sprite', sprite='ltnm_indicator_signal-blue'},
              {type='label', style={font_color={}}, caption='2'}
            }},
            {type='flow', style={vertical_align='center'}, children={
              {type='sprite', sprite='ltnm_indicator_signal-green'},
              {type='label', style={font_color={}}, caption='1'}
            }}
          }}
        }}
      }}
    end
    children[1].mods = {enabled=false}
    return children
  end,
  depot_trains = function(player)
    local children = {}
    for i=1,7 do
      children[#children+1] = {type='flow', style={padding=4, horizontal_spacing=12}, children={
        {type='frame', style='ltnm_dark_content_frame_in_light_frame', children={
          {type='minimap', style={width=72, height=72}, position=player.position, zoom=2},
        }},
        {type='flow', children={
          {type='label', caption='Delivering'},
          {template='pushers.horizontal'}
        }},
        {type='flow', children={
          {type='label', caption='MAIN drop 4'},
          {template='pushers.horizontal'}
        }},
        {type='frame', style='ltnm_dark_content_frame_in_light_frame', children={
          {type='scroll-pane', style='ltnm_small_icon_slot_table_scroll_pane', vertical_scroll_policy='always', children={
            {type='table', style={name='ltnm_icon_slot_table', width=144}, column_count=4, children=gui.call_template('train_contents', i == 1 and 22 or 3)}
          }}
        }}
      }}
      if i ~= 7 then
        children[#children+1] = {type='line', style={horizontally_stretchable=true}, direction='horizontal'}
      end
    end
    return children
  end
}

local train_column_widths = {
  minimap = 72,
  status = 156,
  destination = 170,
  contents = 156
}

-- -----------------------------------------------------------------------------
-- GUI MANAGEMENT

function self.create(player, player_table)
  local gui_data = gui.create(player.gui.screen, 'main', player.index,
    {type='frame', style='ltnm_empty_frame', direction='vertical', save_as='window', children={
      {type='tabbed-pane', style='ltnm_tabbed_pane', children={
        -- depots tab
        {type='tab-and-content', tab={type='tab', style='ltnm_main_tab', caption={'ltnm-gui.depots'}}, content=
          {type='flow', style={vertical_spacing=12}, direction='vertical', children={
            -- buttons
            {type='frame', style='ltnm_dark_content_frame', direction='vertical', children={
              {type='scroll-pane', style='ltnm_depots_scroll_pane', horizontal_scroll_policy='never', children={
                {type='table', style='ltnm_depots_table', column_count=3, children=gui.call_template('depot_buttons', player)}
              }}
            }},
            -- trains
            {type='frame', style='ltnm_light_content_frame', direction='vertical', children={
              -- toolbar
              {type='frame', style='subheader_frame', children={
                {type='flow', style={vertical_align='center', height=28, horizontal_spacing=12, left_margin=4}, children={
                  {type='label', style={name='bold_label', horizontal_align='center', width=72}, caption='Preview'},
                  {type='label', style={name='bold_label', width=156}, caption='Status'},
                  {type='label', style={name='bold_label', width=170}, caption='Destination'},
                  {type='label', style={name='bold_label'}, caption='Contents'},
                  {template='pushers.horizontal'}
                }}
              }},
              -- trains
              {type='scroll-pane', style={name='ltnm_blank_scroll_pane', height=398}, horizontal_scroll_policy='never', children=gui.call_template('depot_trains', player)}
            }}
          }}
        },
        -- stations tab
        {type='tab-and-content', tab={type='tab', style='ltnm_main_tab', caption={'ltnm-gui.stations'}}, content=
          {type='frame', style='ltnm_dark_content_frame', direction='vertical', children={
            -- toolbar
            {type='frame', style='subheader_frame', direction='vertical', children={
              {type='flow', style='ltnm_station_labels_flow', direction='horizontal', children={
                {type='empty-widget', style={height=28}},
                {type='label', style={name='bold_label', left_margin=-8, width=220}, caption={'ltnm-gui.station-name'}},
                {type='label', style={name='bold_label', width=168}, caption={'ltnm-gui.provided-requested'}},
                {type='label', style={name='bold_label', width=134}, caption={'ltnm-gui.deliveries'}},
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
              {template='pushers.horizontal'},
              {type='button', style='tool_button', caption='ID'}
            }},
            -- contents
            {type='flow', style={padding=10, horizontal_spacing=10}, direction='horizontal', children={
              -- inventory tables
              {type='flow', style={padding=0}, direction='vertical', children={
                gui.call_template('inventory_slot_table_with_label', 'available'),
                gui.call_template('inventory_slot_table_with_label', 'requested'),
                gui.call_template('inventory_slot_table_with_label', 'in_transit')
              }},
              -- item information
              {type='flow', direction='vertical', children={
                {type='table', style='bordered_table', column_count=1, children={
                  {type='flow', style={vertical_align='center'}, direction='horizontal', children={
                    {type='sprite', style='ltnm_inventory_selected_icon', sprite='item/iron-ore'},
                    {type='label', style='bold_label', caption='Iron ore'},
                    {template='pushers.horizontal'}
                  }}
                }},
                {type='label', style='caption_label', caption={'ltnm-gui.stations'}},
                {type='frame', style='ltnm_dark_content_frame_in_light_frame', children={
                  {type='scroll-pane', style='ltnm_blank_scroll_pane', children={
                    -- demoing frame GUI structure
                    {type='frame', style='ltnm_station_items_frame', direction='vertical', children={
                      -- labels / info
                      {type='flow', direction='horizontal', children={
                        {type='label', style='bold_label', caption='Lorem ipsum'},
                        {template='pushers.horizontal'},
                        {type='label', caption='[font=default-bold]ID: [/font]3'}
                      }},
                      -- provided / requested
                      {type='table', style={horizontal_spacing=2, vertical_spacing=2}, column_count=8, children=gui.call_template('demo_station_contents')}
                    }}
                  }}
                }},
                {type='label', style='caption_label', caption={'ltnm-gui.deliveries'}},
                {type='frame', style='ltnm_dark_content_frame_in_light_frame', children={
                  {type='scroll-pane', style='ltnm_blank_scroll_pane', children={
                    -- demoing frame GUI structure
                    {type='frame', style='ltnm_station_items_frame', direction='vertical', children={
                      -- labels / info
                      {type='flow', direction='horizontal', children={
                        {type='label', style='bold_label', caption='Lorem ipsum  ->  Dolor sit amet'},
                        {template='pushers.horizontal'}
                      }},
                      -- provided / requested
                      {type='table', style={horizontal_spacing=2, vertical_spacing=2}, column_count=8, children=gui.call_template('demo_station_contents')}
                    }}
                  }}
                }}
              }}
            }}
          }}
        },
        -- history tab
        {type='tab-and-content', tab={type='tab', style='ltnm_main_tab', caption={'ltnm-gui.history'}}, content=
          {type='empty-widget'}
        },
        -- alerts tab
        {type='tab-and-content', tab={type='tab', style='ltnm_main_tab', caption={'ltnm-gui.alerts'}}, content=
          {type='empty-widget'}
        },
        -- frame header
        {type='tab-and-content',
          tab = {type='tab', style={name='ltnm_tabbed_pane_header', horizontally_stretchable=true, width=222}, mods={enabled=false}, children={
            {type='flow', style={vertical_align='center'}, direction='horizontal', children={
              {type='empty-widget', style={name='draggable_space_header', horizontally_stretchable=true, height=24, width=177, left_margin=0, right_margin=4},
                save_as='drag_handle'},
              {type='frame', style='ltnm_close_button_shadow_frame', children={
                {template='close_button'}
              }}
            }}
          }},
          content = {type='empty-widget'}
        }
      }}
    }}
  )

  -- dragging and centering
  gui_data.drag_handle.drag_target = gui_data.window
  gui_data.window.force_auto_center()

  player_table.gui.main = gui_data

  -- set initial contents
  self.update(player, player_table)
end

-- completely destroys the GUI
function self.destroy(player, player_table)
  gui.destroy(player_table.gui.main.window, 'main', player.index)
  player_table.gui.main = nil
end

-- updates the contents of the GUI
function self.update(player, player_table)
  local gui_data = player_table.gui.main
  local data = global.data

  -- DEPOTS
  do
    local pane = gui_data.depots_scroll_pane

  end

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
              table.add{type='sprite-button', style='ltnm_bordered_slot_button_green', sprite=string_gsub(name, ',', '/'), number=count}
            end
          end
          if t.requests then
            local materials = t.requests
            for name,count in pairs(materials) do
              i = i + 1
              table.add{type='sprite-button', style='ltnm_bordered_slot_button_red', sprite=string_gsub(name, ',', '/'), number=-count}
            end
          end
          if i%5 ~= 0 or i == 0 then
            for _=1,5-(i%5) do
              table.add{type='sprite-button', style='ltnm_bordered_slot_button_dark_grey'}
            end
          end
        end
        -- active deliveries
        do
          local deliveries = data.deliveries
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
            table.add{type='sprite-button', style='ltnm_bordered_slot_button_dark_grey', sprite=string_gsub(name, ',', '/'), number=count}
          end
          if i%4 ~= 0 or i == 0 then
            for _=1,4-(i%4) do
              table.add{type='sprite-button', style='ltnm_bordered_slot_button_dark_grey'}
            end
          end
        end
        -- ltn combinator button
        frame.add{type='sprite-button', style='ltnm_bordered_slot_button_dark_grey', sprite='item/constant-combinator'}
      end
    end
  end

  -- INVENTORY
  local inventory = data.inventory
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

end

return self

--[[
  depot_trains = function(player)
    local children = {}
    for i=1,7 do
      children[#children+1] = {type='frame', style='ltnm_depot_frame', children={
        {type='frame', style='ltnm_dark_content_frame_in_light_frame', children={
          {type='minimap', style={width=64, height=64}, position=player.position, zoom=1.5}
        }},
        {type='flow', style={left_margin=4}, direction='vertical', children={
          {type='flow', children={
            {type='label', style='caption_label', caption='Status:'},
            {type='label', caption='Delivering'},
            {template='pushers.horizontal'},
            {type='label', style='caption_label', caption='Destination:'},
            {type='label', caption='MAIN mixed in'},
            {template='pushers.horizontal'},
            {type='label', style='caption_label', caption='Runtime:'},
            {type='label', caption='1:33'}
          }},
          {type='flow', style={vertical_align='center', top_margin=4, horizontal_spacing=8}, children={
            {type='label', style='caption_label', caption='Contents:'},
            {type='frame', style='ltnm_dark_content_frame_in_light_frame', children={
              {type='scroll-pane', style='ltnm_small_icon_slot_table_scroll_pane', children={
                {type='flow', style={horizontal_spacing=0, padding=0, margin=0}, children=gui.call_template('train_contents')}
              }}
            }}
          }}
        }}
      }}
    end
    return children
  end,
  depots = function(player)
    local children = {}
    for i=1,3 do
      children[#children+1] = {type='frame', style='ltnm_depot_frame', direction='vertical', children={
        -- top info pane
        {type='flow', style={vertical_align='center', bottom_margin=4}, direction='horizontal', children={
          {type='label', style='caption_label', caption='Depot'},
          {template='pushers.horizontal'},
          {type='label', style='bold_label', caption='Available trains:'},
          {type='label', caption='1/5'},
          {template='pushers.horizontal'},
          {type='flow', style={horizontal_spacing=8}, children={
            {type='flow', style={vertical_align='center'}, children={
              {type='sprite', sprite='ltnm_indicator_signal-blue'},
              {type='label', caption='2'}
            }},
            {type='flow', style={vertical_align='center'}, children={
              {type='sprite', sprite='ltnm_indicator_signal-green'},
              {type='label', caption='1'}
            }}
          }}
        }},
        -- trains list
        {type='frame', style='ltnm_dark_content_frame_in_light_frame', children={
          {type='scroll-pane', style={name='ltnm_trains_scroll_pane', maximal_height=256}, children=gui.call_template('depot_trains', player)}
        }}
      }}
    end
    return children
  end
]]