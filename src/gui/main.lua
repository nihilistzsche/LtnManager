-- -------------------------------------------------------------------------------------------------------------------------------------------------------------
-- MAIN GUI
-- The main GUI for the mod

-- dependencies
local constants = require('scripts.constants')
local event = require('__RaiLuaLib__.lualib.event')
local gui = require('__RaiLuaLib__.lualib.gui')
local util = require('scripts.util')

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
  close_button = {type='sprite-button', style='close_button', sprite='utility/close_white', hovered_sprite='utility/close_black',
    clicked_sprite='utility/close_black', mouse_button_filter={'left'}, handlers='titlebar.close_button', save_as='titlebar.close_button'},
  mock_frame_tab = {type='button', style='ltnm_mock_frame_tab', mouse_button_filter={'left'}, handlers='titlebar.frame_tab'},
  depot_status_indicator = function(name, color, value)
    return {type='flow', style={vertical_align='center'}, children={
      {type='sprite', style='ltnm_status_icon', sprite='ltnm_indicator_'..color, save_as=name..'_circle'},
      {type='label', style={font_color={}}, caption=value, save_as=name..'_label'}
    }}
  end,
  station_slot_table = function(name)
    return {type='frame', style='ltnm_station_slot_table_frame', save_as=name..'_frame', children={
      {type='scroll-pane', style='ltnm_station_slot_table_scroll_pane', save_as=name..'_scroll_pane', children={
        {type='table', style='ltnm_small_slot_table', column_count=4, save_as=name..'_table'}
      }}
    }}
  end,
  inventory = {
    slot_table_with_label = function(name)
      return {type='flow', direction='vertical', children={
        {type='label', style='caption_label', caption={'ltnm-gui.'..string_gsub(name, '_', '-')}},
        {type='frame', style='ltnm_dark_content_frame_in_light_frame', children={
          {type='scroll-pane', style='ltnm_slot_table_scroll_pane', vertical_scroll_policy='always', children={
            {type='table', style='ltnm_inventory_slot_table', column_count=6, save_as='inventory.'..name..'_table'}
          }}
        }}
      }}
    end,
    label_with_value = function(name, label_caption, value)
      return {type='flow', style={left_margin=2, right_margin=2}, children={
        {type='label', style='bold_label', caption={'', label_caption, ':'}, save_as='inventory.info_pane.'..name..'_label'},
        {template='pushers.horizontal'},
        {type='label', caption=value, save_as='inventory.info_pane.'..name..'_value'}
      }}
    end
  }
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
  elseif name == 'stations' then
    changes.stations_list = true
  elseif name == 'inventory' then
    changes.inventory_contents = true
  end
  self.update(player, player_table, changes)
end

gui.add_handlers('main', {
  titlebar = {
    frame_tab = {
      on_gui_click = function(e)
        log('click!')
        local name = e.default_tab or string_gsub(e.element.caption[1], 'ltnm%-gui%.', '')
        update_active_tab(game.get_player(e.player_index), global.players[e.player_index], name)
      end
    },
    close_button = {
      on_gui_click = function(e)
        self.destroy(game.get_player(e.player_index), global.players[e.player_index])
      end
    },
    refresh_button = {
      on_gui_click = function(e)
        local player_table = global.players[e.player_index]
        update_active_tab(game.get_player(e.player_index), global.players[e.player_index], player_table.gui.main.tabbed_pane.selected)
      end
    }
  },
  depots = {
    depot_button = {
      on_gui_click = function(e)
        local _,_,name = string_find(e.element.name, '^ltnm_depot_button_(.*)$')
        self.update(game.get_player(e.player_index), global.players[e.player_index], {selected_depot=name})
      end
    }
  },
  inventory = {
    material_button = {
      on_gui_click = function(e)
        local _,_,name = string_find(e.element.name, '^ltnm_inventory_slot_button_(.*)$')
        self.update(game.get_player(e.player_index), global.players[e.player_index], {selected_material=name})
      end
    }
  }
})

-- -----------------------------------------------------------------------------
-- GUI MANAGEMENT

function self.create(player, player_table)
  local gui_data = gui.build(player.gui.screen, 'main', player.index,
    {type='frame', style='ltnm_empty_frame', direction='vertical', save_as='window', children={
      -- TITLEBAR
      {type='flow', style={horizontal_spacing=0}, direction='horizontal', children={
        {template='mock_frame_tab', caption={'ltnm-gui.depots'}, save_as='tabbed_pane.tabs.depots'},
        {template='mock_frame_tab', caption={'ltnm-gui.stations'}, save_as='tabbed_pane.tabs.stations'},
        {template='mock_frame_tab', caption={'ltnm-gui.inventory'}, save_as='tabbed_pane.tabs.inventory'},
        {template='mock_frame_tab', caption={'ltnm-gui.history'}, save_as='tabbed_pane.tabs.history'},
        {template='mock_frame_tab', caption={'ltnm-gui.alerts'}, save_as='tabbed_pane.tabs.alerts'},
        {type='frame', style='ltnm_main_frame_header', children={
          {type='empty-widget', style={name='draggable_space_header', horizontally_stretchable=true, height=24, left_margin=0, right_margin=4},
            save_as='titlebar.drag_handle'},
          {template='close_button', sprite='ltnm_refresh_white', hovered_sprite='ltnm_refresh_black', clicked_sprite='ltnm_refresh_black',
            tooltip={'ltnm-gui.refresh-current-tab'}, handlers='titlebar.refresh_button', save_as='titlebar.refresh_button'},
          {template='close_button'}
        }}
      }},
      {type='frame', style='ltnm_main_frame_content', children={
        -- DEPOTS
        {type='flow', style={vertical_spacing=12}, direction='vertical', mods={visible=false}, save_as='tabbed_pane.contents.depots', children={
          -- buttons
          {type='frame', style='ltnm_dark_content_frame', direction='vertical', children={
            {type='scroll-pane', style='ltnm_depots_scroll_pane', horizontal_scroll_policy='never', save_as='depots.buttons_scroll_pane', children={
              {type='table', style='ltnm_depots_table', column_count=3, save_as='depots.buttons_table'}
            }}
          }},
          -- trains
          {type='frame', style='ltnm_light_content_frame', direction='vertical', children={
            -- toolbar
            {type='frame', style='ltnm_toolbar_frame', children={
              {type='flow', style={vertical_align='center', height=28, horizontal_spacing=12, left_margin=4}, children={
                {type='label', style='caption_label', caption={'ltnm-gui.train-status'}},
                {template='pushers.horizontal'},
                {type='label', style={name='caption_label', width=144}, caption={'ltnm-gui.shipment'}},
              }}
            }},
            -- trains
            {type='scroll-pane', style={name='ltnm_blank_scroll_pane', vertically_stretchable=true}, save_as='depots.trains_scrollpane'}
          }}
        }},
        -- STATIONS
        {type='frame', style='ltnm_light_content_frame', direction='vertical', mods={visible=false}, save_as='tabbed_pane.contents.stations', children={
          -- toolbar
          {type='frame', style={name='ltnm_toolbar_frame', horizontally_stretchable=true}, direction='vertical', children={
            {type='flow', style='ltnm_station_labels_flow', direction='horizontal', children={
              {type='empty-widget', style={height=28}},
              {type='label', style={name='caption_label', left_margin=-8, width=220}, caption={'ltnm-gui.station-name'}},
              {type='label', style={name='caption_label', width=144}, caption={'ltnm-gui.provided-requested'}},
              {type='label', style={name='caption_label', width=144}, caption={'ltnm-gui.deliveries'}},
              {template='pushers.horizontal'},
              -- {type='sprite-button', style='tool_button', sprite='ltnm_filter', tooltip={'ltnm-gui.station-filters-tooltip'}}
            }}
          }},
          {type='scroll-pane', style='ltnm_stations_scroll_pane', direction='vertical', save_as='stations.scroll_pane'}
        }},
        -- INVENTORY
        {type='frame', style='ltnm_light_content_frame', direction='vertical', mods={visible=false}, save_as='tabbed_pane.contents.inventory', children={
          -- toolbar
          {type='frame', style={name='ltnm_toolbar_frame', height=nil}, direction='horizontal', children={
            {template='pushers.horizontal'},
            {type='button', style='tool_button', caption='ID'}
          }},
          -- contents
          {type='flow', style={padding=10, horizontal_spacing=10}, direction='horizontal', children={
            -- inventory tables
            {type='flow', style={padding=0}, direction='vertical', children={
              gui.call_template('inventory.slot_table_with_label', 'provided'),
              gui.call_template('inventory.slot_table_with_label', 'requested'),
              gui.call_template('inventory.slot_table_with_label', 'in_transit')
            }},
            -- item information
            {type='frame', style={name='ltnm_light_content_frame_in_light_frame', horizontally_stretchable=true, vertically_stretchable=true}, direction='vertical', children={
              {type='frame', style='ltnm_toolbar_frame', direction='vertical', children={
                -- icon and name
                {type='flow', style={vertical_align='center'}, children={
                  {type='sprite', style='ltnm_material_icon', sprite='item-group/intermediate-products', save_as='inventory.info_pane.icon'},
                  {type='label', style={name='caption_label', left_margin=2}, caption={'ltnm-gui.choose-an-item'}, save_as='inventory.info_pane.name'},
                  {template='pushers.horizontal'},
                }},
                -- info
                gui.call_template('inventory.label_with_value', 'provided', {'ltnm-gui.provided'}, 0),
                gui.call_template('inventory.label_with_value', 'requested', {'ltnm-gui.requested'}, 0),
                gui.call_template('inventory.label_with_value', 'in_transit', {'ltnm-gui.in-transit'}, 0)
              }},
              {type='scroll-pane', style={name='ltnm_material_locations_scroll_pane', horizontally_stretchable=true, vertically_stretchable=true},
                save_as='inventory.locations_scroll_pane'}
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

  -- other handlers
  gui.register_handlers('main', 'inventory.material_button', {player_index=player.index, gui_filters='ltnm_inventory_slot_button_'})

  -- set initial contents
  gui.call_handler('main.titlebar.frame_tab.on_gui_click', {name=defines.events.on_gui_click, tick=game.tick, player_index=player.index, default_tab='depots'})
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
    gui.deregister_handlers('main', 'depots.depot_button', player.index)

    local buttons_data = {}

    local button_index = 0
    local num_depots = table_size(data.depots)
    local button_style = num_depots > 6 and 'ltnm_depot_button_for_scrollbar' or 'ltnm_depot_button'

    -- edit scroll pane style depending on number of depots
    if num_depots > 6 then
      gui_data.depots.buttons_scroll_pane.style = 'ltnm_depots_scroll_pane_for_scrollbar'
    else
      gui_data.depots.buttons_scroll_pane.style = 'ltnm_depots_scroll_pane'
    end

    -- build all buttons as if they're inactive
    for name,t in pairs(data.depots) do
      button_index = button_index + 1
      local elems = gui.build(buttons_table, 'main', player.index,
        {type='button', name='ltnm_depot_button_'..name, style=button_style, handlers='depots.depot_button', save_as='button', children={
          {type='flow', ignored_by_interaction=true, direction='vertical', children={
            {type='label', style={name='caption_label', font_color={28, 28, 28}}, caption=name, save_as='name_label'},
            {type='flow', direction='horizontal', children={
              {type='label', style={name='bold_label', font_color={28, 28, 28}}, caption={'', {'ltnm-gui.trains'}, ':'}, save_as='bold_labels.trains'},
              {type='label', style={font_color={}}, caption=t.available_trains..'/'..t.num_trains, save_as='standard_labels.trains'}
            }},
            {type='flow', style={vertical_align='center', horizontal_spacing=6}, save_as='status_flow', children={
              {type='label', style={name='bold_label', font_color={28, 28, 28}}, caption={'', {'ltnm-gui.status'}, ':'}, save_as='bold_labels.status'}
            }}
          }}
        }}
      )
      local statuses = {}
      for _,station_id in ipairs(t.stations) do
        local status = data.stations[station_id].status
        statuses[status.name] = (statuses[status.name] or 0) + status.count
      end
      local status_flow = elems.status_flow
      for status_name, status_count in pairs(statuses) do
        local output = gui.build(status_flow, gui.call_template('depot_status_indicator', 'indicator', status_name, status_count))
        elems.standard_labels[status_name] = output.indicator_label
      end

      -- add elems to button table
      buttons_data[name] = elems
    end

    gui_data.depots.amount = button_index
    gui_data.depots.buttons = buttons_data

    -- set selected depot button
    if data.depots[gui_data.depots.selected] then
      state_changes.selected_depot = state_changes.selected_depot or gui_data.depots.selected
    else
      state_changes.selected_depot = true
      gui_data.depots.selected = nil
    end
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
      local train = data.trains[train_id]
      -- build GUI structure
      local elems = gui.build(trains_pane,
        {type='flow', style={padding=4, vertical_align='center'}, children={
          {type='flow', style={horizontally_stretchable=true, vertical_spacing=-1, top_padding=-2, bottom_padding=-1}, direction='vertical',
            save_as='status_flow'},
          {type='flow', style={padding=0, margin=0}, save_as='composition_flow'},
          {type='frame', style='ltnm_dark_content_frame_in_light_frame', children={
            {type='scroll-pane', style='ltnm_train_slot_table_scroll_pane', children={
              {type='table', style='ltnm_small_slot_table', column_count=4, save_as='contents_table'}
            }}
          }}
        }}
      )
      -- train status
      local status_flow = elems.status_flow
      local state = train.state
      local def = defines.train_state
      if state == def.on_the_path or state == def.arrive_signal or state == def.wait_signal or state == def.arrive_station then
        if train.returning_to_depot then
          status_flow.add{type='label', style='bold_label', caption={'ltnm-gui.returning-to-depot'}}
        else
          status_flow.add{type='label', caption={'', {'ltnm-gui.'..(train.pickupDone and 'delivering-to' or 'fetching-from')}, ':'}}
          status_flow.add{type='label', style='bold_label', caption=train.to}
        end
      elseif state == def.wait_station then
        if train.surface or train.returning_to_depot then
          status_flow.add{type='label', style='bold_label', caption={'ltnm-gui.parked-at-depot'}}
        else
          status_flow.add{type='label', caption={'', {'ltnm-gui.'..(train.pickupDone and 'unloading-at' or 'loading-at')}, ':'}}
          status_flow.add{type='label', style='bold_label', caption=train.from or train.to}
        end
      else
        local breakpoint
      end
      -- contents table
      if train.shipment then
        local contents_table = elems.contents_table
        for name,count in pairs(train.shipment) do
          contents_table.add{type='sprite-button', style='ltnm_small_slot_button_green', sprite=string_gsub(name, ',', '/'), number=count}
        end
      end
      -- add separator
      trains_pane.add{type='line', direction='horizontal'}.style.horizontally_stretchable = true
    end
    local num_children = #trains_pane.children
    if num_children > 1 then
      trains_pane.children[num_children].destroy()
    else
      gui.build(trains_pane,
        {type='flow', style={horizontally_stretchable=true, vertically_stretchable=true, horizontal_align='center', vertical_align='center'}, children={
          {type='label', caption={'ltnm-gui.select-a-depot-to-show-trains'}}
        }}
      )
    end
  end

  -- STATION FILTERS
  if state_changes.station_filters then

  end

  -- STATION SORT
  if state_changes.station_sort then

  end

  -- not used externally, but is called by the above two situations
  if state_changes.stations_list then
    local stations_pane = gui_data.stations.scroll_pane
    stations_pane.clear()

    local stations = data.stations
    for id,t in pairs(stations) do
      if not t.isDepot then -- don't include depots in the stations list
        -- build GUI structure
        local elems = gui.build(stations_pane,
          {type='flow', style={vertical_align='center', horizontal_spacing=12, left_margin=2, right_margin=2}, children={
            -- name / status
            {type='flow', style={vertical_align='center', width=220}, children={
              {type='sprite', style='ltnm_station_status_icon', sprite='ltnm_indicator_'..t.status.name},
              {type='label', style={left_margin=2}, caption=t.entity.backer_name}
            }},
            -- items
            gui.call_template('station_slot_table', 'provided_requested'),
            gui.call_template('station_slot_table', 'deliveries'),
            -- ltn combinator button
            {type='flow', style={right_margin=2}, children={
              {template='pushers.horizontal'},
              {type='frame', style='ltnm_combinator_button_frame', children={
                {type='sprite-button', style='ltnm_combinator_button', sprite='item/constant-combinator', tooltip={'ltnm-gui.open-ltn-combinator-interface'}}
              }}
            }}
          }}
        )
        stations_pane.add{type='line', direction='horizontal'}.style.horizontally_stretchable = true

        -- add provided/requested materials
        local table_add = elems.provided_requested_table.add
        local provided_requested_rows = 0
        for key,color in pairs{provided='green', requested='red'} do
          local materials = t[key]
          if materials then
            for name,count in pairs(materials) do
              provided_requested_rows = provided_requested_rows + 1
              table_add{type='sprite-button', style='ltnm_small_slot_button_'..color, sprite=string_gsub(name, ',', '/'), number=count}
            end
          end
        end
        provided_requested_rows = math.ceil(provided_requested_rows / 4) -- number of columns

        -- add active deliveries
        local deliveries = t.activeDeliveries
        table_add = elems.deliveries_table.add
        local deliveries_rows = 0
        for i=1,#deliveries do
          local shipment = data.trains[deliveries[i]].shipment
          for name,count in pairs(shipment) do
            deliveries_rows = deliveries_rows + 1
            table_add{type='sprite-button', style='ltnm_small_slot_button_dark_grey', sprite=string_gsub(name, ',', '/'), number=count}
          end
        end
        deliveries_rows = math.ceil(deliveries_rows / 4) -- number of columns
        
        local num_rows = math.max(provided_requested_rows, deliveries_rows)
        
        -- set scroll pane properties
        if provided_requested_rows > 3 then
          elems.provided_requested_frame.style.right_margin = -12
          elems.deliveries_frame.style = 'ltnm_station_slot_table_frame_adjacent'
        end
        if deliveries_rows > 3 then
          elems.deliveries_frame.style.right_margin = -12
        end
        if num_rows > 1 then
          local frame_height = 36 * math.min(num_rows, 3)
          elems.provided_requested_frame.style.height = frame_height
          elems.provided_requested_scroll_pane.style.height = frame_height
          elems.deliveries_frame.style.height = frame_height
          elems.deliveries_scroll_pane.style.height = frame_height
        end
      end
    end

    stations_pane.children[#stations_pane.children].destroy()
  end

  -- INVENTORY CONTENTS
  -- also not used externally
  if state_changes.inventory_contents then
    local inventory = data.inventory
    gui_data.inventory.material_buttons = {}
    local buttons = gui_data.inventory.material_buttons
    for type,color in pairs{provided='green', requested='red', in_transit='blue'} do
      -- combine materials (temporary until network filters become a thing)
      local combined_materials = {}
      for _,materials in pairs(inventory[type]) do
        combined_materials = util.add_materials(materials, combined_materials)
      end
      -- add to table
      local table = gui_data.inventory[type..'_table']
      table.clear()
      local add = table.add
      local elems = {}
      for name,count in pairs(combined_materials) do
        elems[name] = add{type='sprite-button', name='ltnm_inventory_slot_button_'..name, style='ltnm_slot_button_'..color,
          sprite=string_gsub(name, ',', '/'), number=count}
      end
      buttons[type] = elems
    end
    -- remove previous selection since the buttons are no longer glowing
    state_changes.selected_material = state_changes.selected_material or gui_data.inventory.selected
    gui_data.inventory.selected = nil
  end

  -- SELECTED MATERIAL
  if state_changes.selected_material then
    -- set selected button glow
    local inventory_gui_data = gui_data.inventory
    for _,type in ipairs{'provided', 'requested', 'in_transit'} do
      local buttons = inventory_gui_data.material_buttons[type]
      -- deselect previous button
      local button = buttons[inventory_gui_data.selected]
      if button then
        button.style = string_gsub(button.style.name, 'ltnm_active_', 'ltnm_')
        button.ignored_by_interaction = false
      end
      -- select new button
      button = buttons[state_changes.selected_material]
      if button then
        button.style = string_gsub(button.style.name, 'ltnm_', 'ltnm_active_')
        button.ignored_by_interaction = true
      end
    end

    -- save selection to global
    inventory_gui_data.selected = state_changes.selected_material

    -- basic material info
    local _, _, material_type, material_name = string_find(state_changes.selected_material, '(.*),(.*)')
    local info_pane = inventory_gui_data.info_pane
    info_pane.icon.sprite = material_type..'/'..material_name
    info_pane.name.caption = game[material_type..'_prototypes'][material_name].localised_name

    -- TODO: available/requested/in transit numbers (requires some data manager processing)

    -- set up scroll pane and locals
    local locations_pane = inventory_gui_data.locations_scroll_pane
    locations_pane.clear()
    local pane_add = locations_pane.add
    local locations = data.material_locations[state_changes.selected_material]

    -- stations
    local stations = data.stations
    local station_ids = locations.stations
    if #station_ids > 0 then
      gui.build(locations_pane,
        {type='flow', children={
          {type='label', style='caption_label', caption={'ltnm-gui.stations'}},
          {template='pushers.horizontal'}
        }}
      )
      pane_add{type='line', style='ltnm_material_locations_line', direction='horizontal'}
      for i=1,#station_ids do
        local station = stations[station_ids[i]]
        if station then
          local materials_table = gui.build(locations_pane,
            {type='flow', direction='vertical', children={
              {type='label', style='bold_label', caption=station.entity.backer_name},
              {type='frame', style='ltnm_dark_content_frame_in_light_frame', children={
                {type='scroll-pane', style='ltnm_material_location_slot_table_scroll_pane', children={
                  {type='table', style='ltnm_small_slot_table', column_count=8, save_as='table'}
                }}
              }}
            }}
          ).table
          local table_add = materials_table.add
          for mode,color in pairs{provided='green', requested='red'} do
            local materials = station[mode]
            if materials then
              for name,count in pairs(materials) do
                table_add{type='sprite-button', style='ltnm_small_slot_button_'..color, sprite=string_gsub(name, ',', '/'), number=count}
              end
            end
          end
          pane_add{type='line', style='ltnm_material_locations_line', direction='horizontal'}
        else
          error('Could not find station of ID: '..station_ids[i])
        end
      end
    end

    -- stations
    local trains = data.trains
    local train_ids = locations.trains
    if #train_ids > 0 then
      gui.build(locations_pane,
        {type='flow', children={
          {type='label', style='caption_label', caption={'ltnm-gui.trains'}},
          {template='pushers.horizontal'}
        }}
      )
      pane_add{type='line', style='ltnm_material_locations_line', direction='horizontal'}
      for i=1,#train_ids do
        local train = trains[train_ids[i]]
        if train then
          local materials_table = gui.build(locations_pane,
            {type='flow', direction='vertical', children={
              {type='label', style='bold_label', caption=train.from..'  ->  '..train.to},
              {type='frame', style='ltnm_dark_content_frame_in_light_frame', children={
                {type='scroll-pane', style='ltnm_material_location_slot_table_scroll_pane', children={
                  {type='table', style='ltnm_small_slot_table', column_count=8, save_as='table'}
                }}
              }}
            }}
          ).table
          local table_add = materials_table.add
          local materials = train.shipment
          if materials then
            for name,count in pairs(materials) do
              table_add{type='sprite-button', style='ltnm_small_slot_button_blue', sprite=string_gsub(name, ',', '/'), number=count}
            end
          end
          pane_add{type='line', style='ltnm_material_locations_line', direction='horizontal'}
        else
          error('Could not find train of ID: '..train_ids[i])
        end
      end
    end
  end
end

return self