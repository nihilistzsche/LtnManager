-- -------------------------------------------------------------------------------------------------------------------------------------------------------------
-- MAIN GUI
-- The main GUI for the mod

-- dependencies
local constants = require('scripts/constants')
local event = require('lualib/event')
local gui = require('lualib/gui')
local util = require('scripts/util')

-- locals
local string_find = string.find
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
    clicked_sprite='utility/close_black', mouse_button_filter={'left'}, handlers='close_button', save_as='titlebar.close_button'},
  mock_frame_tab = {type='button', style='ltnm_mock_frame_tab', mouse_button_filter={'left'}}
}

-- TEMPORARY, FOR LAYOUT PROTOTYPING
gui.add_templates{
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
  end
}

local function update_active_tab(player, player_table, name)
  local changes = {active_tab=name}
  if name == 'depots' then
    changes.depot_buttons = true
    changes.selected_depot = player_table.gui.main.depots.selected or true
  end
  self.update(player, player_table, changes)
end

gui.add_handlers('main', {
  close_button = {
    on_gui_click = function(e)
      self.destroy(game.get_player(e.player_index), global.players[e.player_index])
    end
  },
  depot_button = {
    on_gui_click = function(e)
      local _,_,name = string_find(e.element.name, '^ltnm_depot_button_(.*)$')
      self.update(game.get_player(e.player_index), global.players[e.player_index], {selected_depot=name})
    end
  },
  frame_tab = {
    on_gui_click = function(e)
      local name = e.default_tab or string_gsub(e.element.caption[1], 'ltnm%-gui%.', '')
      update_active_tab(game.get_player(e.player_index), global.players[e.player_index], name)
    end
  },
  refresh_button = {
    on_gui_click = function(e)
      local player_table = global.players[e.player_index]
      update_active_tab(game.get_player(e.player_index), global.players[e.player_index], player_table.gui.main.tabbed_pane.selected)
    end
  }
})

-- -----------------------------------------------------------------------------
-- GUI MANAGEMENT

function self.create(player, player_table)
  local gui_data = gui.build(player.gui.screen, 'main', player.index,
    {type='frame', style='ltnm_empty_frame', direction='vertical', save_as='window', children={
      -- TITLEBAR
      {type='flow', style={horizontal_spacing=0}, direction='horizontal', children={
        {template='mock_frame_tab', caption={'ltnm-gui.depots'}, handlers='frame_tab', save_as='tabbed_pane.tabs.depots'},
        {template='mock_frame_tab', caption={'ltnm-gui.stations'}, handlers='frame_tab', save_as='tabbed_pane.tabs.stations'},
        {template='mock_frame_tab', caption={'ltnm-gui.inventory'}, handlers='frame_tab', save_as='tabbed_pane.tabs.inventory'},
        {template='mock_frame_tab', caption={'ltnm-gui.history'}, handlers='frame_tab', save_as='tabbed_pane.tabs.history'},
        {template='mock_frame_tab', caption={'ltnm-gui.alerts'}, handlers='frame_tab', save_as='tabbed_pane.tabs.alerts'},
        {type='frame', style='ltnm_main_frame_header', children={
          {type='empty-widget', style={name='draggable_space_header', horizontally_stretchable=true, height=24, left_margin=0, right_margin=4},
            save_as='titlebar.drag_handle'},
          {template='close_button', sprite='ltnm_refresh_white', hovered_sprite='ltnm_refresh_black', clicked_sprite='ltnm_refresh_black',
            tooltip={'ltnm-gui.refresh-current-tab'}, handlers='refresh_button', save_as='titlebar.refresh_button'},
          {template='close_button'}
        }}
      }},
      {type='frame', style='ltnm_main_frame_content', children={
        -- DEPOTS
        {type='flow', style={vertical_spacing=12}, direction='vertical', mods={visible=false}, save_as='tabbed_pane.contents.depots', children={
          -- buttons
          {type='frame', style='ltnm_dark_content_frame', direction='vertical', children={
            {type='scroll-pane', style='ltnm_depots_scroll_pane', horizontal_scroll_policy='never', children={
              {type='table', style='ltnm_depots_table', column_count=3, save_as='depots.buttons_table'}
            }}
          }},
          -- trains
          {type='frame', style='ltnm_light_content_frame', direction='vertical', children={
            -- toolbar
            {type='frame', style='subheader_frame', children={
              {type='flow', style={vertical_align='center', height=28, horizontal_spacing=12, left_margin=4}, children={
                {type='label', style='bold_label', caption={'ltnm-gui.train-status'}},
                {template='pushers.horizontal'},
                {type='label', style={name='bold_label', width=144}, caption={'ltnm-gui.shipment'}},
              }}
            }},
            -- trains
            {type='scroll-pane', style={name='ltnm_blank_scroll_pane', vertically_stretchable=true}, save_as='depots.trains_scrollpane'}
          }}
        }},
        -- STATIONS
        {type='frame', style='ltnm_dark_content_frame', direction='vertical', mods={visible=false}, save_as='tabbed_pane.contents.stations', children={
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
        }},
        -- INVENTORY
        {type='frame', style='ltnm_light_content_frame', direction='vertical', mods={visible=false}, save_as='tabbed_pane.contents.inventory', children={
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
        }},
        -- HISTORY
        {type='empty-widget', mods={visible=false}, save_as='tabbed_pane.contents.history'},
        -- ALERTS
        {type='empty-widget', mods={visible=false}, save_as='tabbed_pane.contents.alerts'}
      }}
    }}
  )

  -- dragging and centering
  gui_data.titlebar.drag_handle.drag_target = gui_data.window
  gui_data.window.force_auto_center()

  player_table.gui.main = gui_data

  -- set initial contents
  gui.call_handler('main.frame_tab.on_gui_click', {name=defines.events.on_gui_click, tick=game.tick, player_index=player.index, default_tab='depots'})
end

-- completely destroys the GUI
function self.destroy(player, player_table)
  gui.deregister_all('main', player.index)
  player_table.gui.main.window.destroy()
  player_table.gui.main = nil
end

-- -------------------------------------
-- STATE UPDATES

-- updates the contents of the GUI
function self.update(player, player_table, state_changes)
  local gui_data = player_table.gui.main
  local data = global.data

  -- ACTIVE TAB
  if state_changes.active_tab then
    local tabbed_pane_data = gui_data.tabbed_pane
    -- close previous tab, if there was a previous tab
    if tabbed_pane_data.selected then
      tabbed_pane_data.tabs[tabbed_pane_data.selected].enabled = true
      tabbed_pane_data.contents[tabbed_pane_data.selected].visible = false
    end
    -- set new tab to focused
    tabbed_pane_data.tabs[state_changes.active_tab].enabled = false
    tabbed_pane_data.contents[state_changes.active_tab].visible = true
    -- update selected tab in global
    tabbed_pane_data.selected = state_changes.active_tab
  end

  -- DEPOT BUTTONS
  if state_changes.depot_buttons then
    local buttons_table = gui_data.depots.buttons_table
    -- delete old buttons and deregister handler
    buttons_table.clear()
    gui.deregister_handlers('main', 'depot_button', player.index)

    local buttons_data = {}

    local button_index = 0
    -- build all buttons as if they're inactive
    for name,t in pairs(data.depots) do
      button_index = button_index + 1
      local elems = gui.build(buttons_table, 'main', player.index,
        {type='button', name='ltnm_depot_button_'..name, style='ltnm_depot_button', handlers='depot_button', save_as='button', children={
          {type='flow', ignored_by_interaction=true, direction='vertical', children={
            {type='label', style={name='caption_label', font_color={28, 28, 28}}, caption=name, save_as='name_label'},
            {type='flow', direction='horizontal', children={
              {type='label', style={name='bold_label', font_color={28, 28, 28}}, caption={'', {'ltnm-gui.trains'}, ':'}, save_as='bold_labels.trains'},
              {type='label', style={font_color={}}, caption='N/A', save_as='standard_labels.trains'}
            }},
            {type='flow', style={vertical_align='center', horizontal_spacing=6}, save_as='status_flow', children={
              {type='label', style={name='bold_label', font_color={28, 28, 28}}, caption={'', {'ltnm-gui.status'}, ':'}, save_as='bold_labels.status'}
            }}
          }}
        }}
      )
      local statuses = {}
      for _,station_id in ipairs(t.stations) do
        local station = data.stations[station_id]
        local signal = station.lampControl.get_circuit_network(defines.wire_type.red).signals[1]
        local signal_name = signal.signal.name
        statuses[signal_name] = (statuses[signal_name] or 0) + signal.count
      end
      local status_flow = elems.status_flow
      for status_name, status_count in pairs(statuses) do
        local output = gui.build(status_flow,
          {type='flow', style={vertical_align='center'}, children={
            {type='sprite', sprite='ltnm_indicator_'..status_name},
            {type='label', style={font_color={}}, caption=status_count, save_as='label'}
          }}
        )
        elems.standard_labels[status_name] = output.label
      end

      -- add elems to button table
      buttons_data[name] = elems
    end

    gui_data.depots.amount = button_index
    gui_data.depots.buttons = buttons_data

    -- set selected depot button
    state_changes.selected_depot = state_changes.selected_depot or gui_data.depots.selected
  end

  -- SELECTED DEPOT
  if state_changes.selected_depot then
    local depot_data = gui_data.depots

    if depot_data.amount > 0 then
      local new_selection = state_changes.selected_depot
      if new_selection == true then
        -- get the name of the first depot in the list
        _,_,new_selection = string_find(gui_data.depots.buttons_table.children[1].name, '^ltnm_depot_button_(.*)$')
      end
      -- set previous selection to inactive style
      local previous_selection = depot_data.selected
      if previous_selection then
        local button_data = depot_data.buttons[previous_selection]
        button_data.button.enabled = true
        button_data.name_label.style.font_color = constants.bold_dark_font_color
        for _,elem in pairs(button_data.bold_labels) do
          elem.style.font_color = constants.bold_dark_font_color
        end
        for _,elem in pairs(button_data.standard_labels) do
          elem.style.font_color = constants.default_dark_font_color
        end
      end
      -- set new selection to active style
      local button_data = depot_data.buttons[new_selection]
      button_data.button.enabled = false
      button_data.name_label.style.font_color = constants.heading_font_color
      for _,elem in pairs(button_data.bold_labels) do
        elem.style.font_color = constants.default_font_color
      end
      for _,elem in pairs(button_data.standard_labels) do
        elem.style.font_color = constants.default_font_color
      end
      -- update selection in global
      depot_data.selected = new_selection
      -- update trains list
      state_changes.depot_trains = true
    end
  end

  -- DEPOT TRAINS
  if state_changes.depot_trains then
    local trains_pane = gui_data.depots.trains_scrollpane
    trains_pane.clear()

    local trains = data.depots[gui_data.depots.selected].trains
    for _,train_id in ipairs(trains) do
      local train = data.deliveries[train_id]
      -- build GUI structure
      local elems = gui.build(trains_pane,
        {type='flow', style={padding=4, horizontal_spacing=12, vertical_align='center'}, children={
          -- minimaps can't be tied to a specific entity (yet) so we'll omit it for now
          -- {type='frame', style='ltnm_dark_content_frame_in_light_frame', children={
          --   {type='minimap', style={width=72, height=72}, position=train.train.carriages[1].position, zoom=2},
          -- }},
          {type='flow', style={horizontally_stretchable=true, vertical_spacing=-1, top_padding=-2, bottom_padding=-1}, direction='vertical', save_as='status_flow'},
          {type='frame', style='ltnm_dark_content_frame_in_light_frame', children={
            {type='scroll-pane', style='ltnm_small_icon_slot_table_scroll_pane', children={
              {type='table', style={name='ltnm_icon_slot_table', width=144}, column_count=6, save_as='contents_table'}
            }}
          }}
        }}
      )
      -- train status
      local status_flow = elems.status_flow
      local state = train.train.state
      local def = defines.train_state
      if state == def.on_the_path or state == def.arrive_signal or state == def.wait_signal or state == def.arrive_station then
        status_flow.add{type='label', caption={'', {'ltnm-gui.'..(train.pickupDone and 'delivering-to' or 'fetching-from')}, ':'}}
        status_flow.add{type='label', style='bold_label', caption=train.to}
      elseif state == def.wait_station then
        status_flow.add{type='label', caption={'', {'ltnm-gui.'..(train.pickupDone and 'unloading-at' or 'loading-at')}, ':'}}
        status_flow.add{type='label', style='bold_label', caption=train.from}
      else
        local breakpoint
      end
      -- contents table
      local contents_table = elems.contents_table
      for name,count in pairs(train.shipment) do
        contents_table.add{type='sprite-button', style='ltnm_small_slot_button_green', sprite=string_gsub(name, ',', '/'), number=count}
          .ignored_by_interaction = true
      end
      -- add separator
      trains_pane.add{type='line', direction='horizontal'}.style.horizontally_stretchable = true
    end
    trains_pane.children[#trains_pane.children].destroy()
  end

end

return self

--[[
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
]]