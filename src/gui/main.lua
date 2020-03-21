-- -------------------------------------------------------------------------------------------------------------------------------------------------------------
-- MAIN GUI
-- The main GUI for the mod

-- dependencies
local constants = require('scripts.constants')
local event = require('__RaiLuaLib__.lualib.event')
local gui = require('__RaiLuaLib__.lualib.gui')
local util = require('scripts.util')

-- local profiler = require('__profiler__/profiler.lua')

-- locals
local string_find = string.find
local string_gsub = string.gsub

-- self object
local self = {}

-- -----------------------------------------------------------------------------
-- GUI DATA

gui.templates:extend{
  pushers = {
    horizontal = {type='empty-widget', style_mods={horizontally_stretchable=true}},
    vertical = {type='empty-widget', style_mods={vertically_stretchable=true}},
    both = {type='empty-widget', style_mods={horizontally_stretchable=true, vertically_stretchable=true}}
  },
  close_button = {type='sprite-button', style='ltnm_close_button', sprite='utility/close_white', hovered_sprite='utility/close_black',
    clicked_sprite='utility/close_black', mouse_button_filter={'left'}, handlers='main.titlebar.close_button', save_as='titlebar.close_button'},
  mock_frame_tab = {type='button', style='ltnm_mock_frame_tab', mouse_button_filter={'left'}, handlers='main.titlebar.frame_tab'},
  status_indicator = function(name, color, value)
    return {type='flow', style_mods={vertical_align='center'}, children={
      {type='sprite', style='ltnm_status_icon', sprite='ltnm_indicator_'..color, save_as=name..'_circle'},
      {type='label', caption=value, save_as=name..'_label'}
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
      return {type='flow', style_mods={left_margin=2, right_margin=2}, children={
        {type='label', style='bold_label', caption={'', label_caption, ':'}, save_as='inventory.info_pane.'..name..'_label'},
        {template='pushers.horizontal'},
        {type='label', caption=value, save_as='inventory.info_pane.'..name..'_value'}
      }}
    end
  }
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
  elseif name == 'history' then
    changes.history = true
  end
  self.update(player, player_table, changes)
end

gui.handlers:extend{main={
  titlebar = {
    frame_tab = {
      on_gui_click = function(e)
        local name = e.default_tab or string_gsub(e.element.caption[1], 'ltnm%-gui%.', '')
        update_active_tab(game.get_player(e.player_index), global.players[e.player_index], name)
      end
    },
    pin_button = {
      on_gui_click = function(e)
        
      end
    },
    refresh_button = {
      on_gui_click = function(e)
        local player_table = global.players[e.player_index]
        update_active_tab(game.get_player(e.player_index), global.players[e.player_index], player_table.gui.main.tabbed_pane.selected)
      end
    },
    close_button = {
      on_gui_click = function(e)
        self.destroy(game.get_player(e.player_index), global.players[e.player_index])
      end
    },
  },
  depots = {
    depot_button = {
      on_gui_click = function(e)
        local _,_,name = string_find(e.element.name, '^ltnm_depot_button_(.*)$')
        self.update(game.get_player(e.player_index), global.players[e.player_index], {selected_depot=name})
      end
    },
    sort_checkbox = {
      on_gui_checked_state_changed = function(e)
        local _,_,clicked_type = string_find(e.element.name, '^ltnm_sort_train_(.-)$')
        local player_table = global.players[e.player_index]
        local gui_data = player_table.gui.main.depots
        if gui_data.active_sort ~= clicked_type then
          -- reset the checkbox value and switch active sort
          e.element.state = not e.element.state
          gui_data.active_sort = clicked_type
          -- update styles
          e.element.style = 'ltnm_sort_checkbox_active'
          if clicked_type == 'composition' then
            gui_data.status_sort_checkbox.style = 'ltnm_sort_checkbox_inactive'
          else
            gui_data.composition_sort_checkbox.style = 'ltnm_sort_checkbox_inactive'
          end
        else
          gui_data['sort_'..clicked_type] = e.element.state
        end
        self.update(game.get_player(e.player_index), player_table, {depot_trains=true})
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
}}

-- -----------------------------------------------------------------------------
-- GUI MANAGEMENT

function self.create(player, player_table)
  -- profiler.Start()
  local gui_data = gui.build(player.gui.screen, {
    {type='frame', style='ltnm_empty_frame', direction='vertical', save_as='window', children={
      -- TITLEBAR
      {type='flow', style_mods={horizontal_spacing=0}, direction='horizontal', children={
        {template='mock_frame_tab', caption={'ltnm-gui.depots'}, save_as='tabbed_pane.tabs.depots'},
        {template='mock_frame_tab', caption={'ltnm-gui.stations'}, save_as='tabbed_pane.tabs.stations'},
        {template='mock_frame_tab', caption={'ltnm-gui.inventory'}, save_as='tabbed_pane.tabs.inventory'},
        {template='mock_frame_tab', caption={'ltnm-gui.history'}, save_as='tabbed_pane.tabs.history'},
        {template='mock_frame_tab', caption={'ltnm-gui.alerts'}, save_as='tabbed_pane.tabs.alerts'},
        {type='frame', style='ltnm_main_frame_header', children={
          {type='empty-widget', style='draggable_space_header', style_mods={horizontally_stretchable=true, height=24, left_margin=0, right_margin=4},
            save_as='titlebar.drag_handle'},
          {type='sprite-button', style='ltnm_close_button', sprite='ltnm_pin_white', hovered_sprite='ltnm_pin_black', clicked_sprite='ltnm_pin_black',
            tooltip={'ltnm-gui.keep-open'}, handlers='main.titlebar.pin_button', save_as='titlebar.pin_button'},
          {type='sprite-button', style='ltnm_close_button', sprite='ltnm_refresh_white', hovered_sprite='ltnm_refresh_black',
            clicked_sprite='ltnm_refresh_black', tooltip={'ltnm-gui.refresh-current-tab'}, handlers='main.titlebar.refresh_button',
            save_as='titlebar.refresh_button'},
          {template='close_button'}
        }}
      }},
      {type='frame', style='ltnm_main_frame_content', children={
        -- DEPOTS
        {type='flow', style_mods={horizontal_spacing=12}, mods={visible=false}, save_as='tabbed_pane.contents.depots', children={
          -- buttons
          {type='frame', style='ltnm_dark_content_frame', children={
            {type='scroll-pane', style='ltnm_depots_scroll_pane', save_as='depots.buttons_scroll_pane'}
          }},
          -- trains
          {type='frame', style='ltnm_light_content_frame', direction='vertical', children={
            -- toolbar
            {type='frame', style='ltnm_toolbar_frame', children={
              {type='checkbox', name='ltnm_sort_train_composition', style='ltnm_sort_checkbox_active', style_mods={left_margin=8, width=120},
                caption={'ltnm-gui.composition'}, state=true, handlers='main.depots.sort_checkbox', save_as='depots.composition_sort_checkbox'},
              {type='checkbox', name='ltnm_sort_train_status', style='ltnm_sort_checkbox_inactive', caption={'ltnm-gui.train-status'}, state=true,
                handlers='main.depots.sort_checkbox', save_as='depots.status_sort_checkbox'},
              {template='pushers.horizontal'},
              {type='label', style='caption_label', style_mods={width=144}, caption={'ltnm-gui.shipment'}},
              {type='empty-widget', style_mods={width=6}}
            }},
            -- trains
            {type='scroll-pane', style='ltnm_blank_scroll_pane', style_mods={vertically_stretchable=true, horizontally_stretchable=true},
              vertical_scroll_policy='always', save_as='depots.trains_scrollpane', children={
                {type='table', style='ltnm_depot_trains_table', column_count=3, save_as='depots.trains_table'}
              }
            }
          }}
        }},
        -- STATIONS
        {type='frame', style='ltnm_light_content_frame', direction='vertical', mods={visible=false}, save_as='tabbed_pane.contents.stations', children={
          -- toolbar
          {type='frame', style='ltnm_toolbar_frame', children={
            {type='empty-widget', style_mods={height=28}},
            {type='checkbox', style='ltnm_sort_checkbox_active', style_mods={left_margin=-4}, caption={'ltnm-gui.station-name'}, state=true},
            {template='pushers.horizontal'},
            {type='checkbox', style='ltnm_sort_checkbox_inactive', style_mods={horizontal_align='center', width=24}, caption={'ltnm-gui.id'}, state=true},
            {type='checkbox', style='ltnm_sort_checkbox_inactive', style_mods={horizontal_align='center', width=34}, state=true},
            {type='label', style='caption_label', style_mods={width=180}, caption={'ltnm-gui.provided-requested'}},
            {type='label', style='caption_label', style_mods={width=144}, caption={'ltnm-gui.shipments'}},
            {type='label', style='caption_label', style_mods={width=124}, caption={'ltnm-gui.control-signals'}},
            {type='sprite-button', style='tool_button', sprite='ltnm_filter', tooltip={'ltnm-gui.station-filters-tooltip'}}
          }},
          {type='scroll-pane', style='ltnm_blank_scroll_pane', direction='vertical', vertical_scroll_policy='always', save_as='stations.scroll_pane', children={
            {type='table', style='ltnm_stations_table', style_mods={vertically_stretchable=true}, column_count=6, save_as='stations.table'}
          }}
        }},
        -- INVENTORY
        {type='frame', style='ltnm_light_content_frame', direction='vertical', mods={visible=false}, save_as='tabbed_pane.contents.inventory', children={
          -- toolbar
          {type='frame', style='ltnm_toolbar_frame', style_mods={height=nil}, direction='horizontal', children={
            {template='pushers.horizontal'},
            {type='button', style='tool_button', caption='ID'}
          }},
          -- contents
          {type='flow', style_mods={padding=10, horizontal_spacing=10}, direction='horizontal', children={
            -- inventory tables
            {type='flow', style_mods={padding=0}, direction='vertical', children={
              gui.templates.inventory.slot_table_with_label('provided'),
              gui.templates.inventory.slot_table_with_label('requested'),
              gui.templates.inventory.slot_table_with_label('in_transit')
            }},
            -- item information
            {type='frame', style='ltnm_light_content_frame_in_light_frame', style_mods={horizontally_stretchable=true, vertically_stretchable=true},
              direction='vertical', children={
                {type='frame', style='ltnm_toolbar_frame', direction='vertical', children={
                  -- icon and name
                  {type='flow', style_mods={vertical_align='center'}, children={
                    {type='sprite', style='ltnm_material_icon', sprite='item-group/intermediate-products', save_as='inventory.info_pane.icon'},
                    {type='label', style='caption_label', style_mods={left_margin=2}, caption={'ltnm-gui.choose-an-item'}, save_as='inventory.info_pane.name'},
                    {template='pushers.horizontal'},
                  }},
                  -- info
                  gui.templates.inventory.label_with_value('provided', {'ltnm-gui.provided'}, 0),
                  gui.templates.inventory.label_with_value('requested', {'ltnm-gui.requested'}, 0),
                  gui.templates.inventory.label_with_value('in_transit', {'ltnm-gui.in-transit'}, 0)
                }},
                {type='scroll-pane', style='ltnm_material_locations_scroll_pane', style_mods={horizontally_stretchable=true, vertically_stretchable=true},
                  save_as='inventory.locations_scroll_pane'}
              }
            }
          }}
        }},
        -- HISTORY
        {type='frame', style='ltnm_light_content_frame', direction='vertical', mods={visible=false}, save_as='tabbed_pane.contents.history', children={
          -- toolbar
          {type='frame', style='ltnm_toolbar_frame', children={
            {type='checkbox', style='ltnm_sort_checkbox_inactive', state=true, style_mods={width=140, left_margin=8}, caption={'ltnm-gui.depot'}},
            {type='checkbox', style='ltnm_sort_checkbox_inactive', state=true, caption={'ltnm-gui.route'}},
            {template='pushers.horizontal'},
            {type='checkbox', style='ltnm_sort_checkbox_inactive', style_mods={right_margin=8}, state=true, caption={'ltnm-gui.runtime'}},
            {type='label', style='caption_label', style_mods={width=124}, caption={'ltnm-gui.shipment'}},
            {type='sprite-button', style='red_icon_button', sprite='utility/trash', tooltip={'ltnm-gui.clear-history'}, save_as='history.delete_button'}
          }},
          -- listing
          {type='scroll-pane', style='ltnm_blank_scroll_pane', style_mods={horizontally_stretchable=true, vertically_stretchable=true},
            vertical_scroll_policy='always', save_as='history.pane', children={
              {type='table', style='ltnm_rows_table', style_mods={vertically_stretchable=true}, column_count=4, save_as='history.table'}
            }
          }
        }},
        -- ALERTS
        {type='empty-widget', mods={visible=false}, save_as='tabbed_pane.contents.alerts'}
      }}
    }}
  })

  -- other handlers
  event.enable_group('gui.main.inventory.material_button', player.index, 'ltnm_inventory_slot_button_')

  -- default settings
  gui_data.depots.active_sort = 'composition'
  gui_data.depots.sort_composition = true
  gui_data.depots.sort_status = true

  -- dragging and centering
  gui_data.titlebar.drag_handle.drag_target = gui_data.window
  gui_data.window.force_auto_center()

  player_table.gui.main = gui_data


  -- set initial contents
  gui.handlers.main.titlebar.frame_tab.on_gui_click{name=defines.events.on_gui_click, tick=game.tick, player_index=player.index,
    default_tab='depots'}
  -- profiler.Stop()
end

-- completely destroys the GUI
function self.destroy(player, player_table)
  event.disable_group('gui.main', player.index)
  player_table.gui.main.window.destroy()
  player_table.gui.main = nil
  -- set shortcut state
  player.set_shortcut_toggled('ltnm-toggle-gui', false)
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
    local buttons_pane = gui_data.depots.buttons_scroll_pane
    -- delete old buttons and disable handler
    buttons_pane.clear()
    event.disable_group('gui.main.depots.depot_button', player.index)

    local buttons_data = {}

    local button_index = 0

    -- build all buttons as if they're inactive
    for name,t in pairs(data.depots) do
      button_index = button_index + 1
      local elems = gui.build(buttons_pane, {
        {type='button', name='ltnm_depot_button_'..name, style='ltnm_depot_button', handlers='main.depots.depot_button', save_as='button', children={
          {type='flow', ignored_by_interaction=true, direction='vertical', children={
            {type='label', style='caption_label', style_mods={font_color={28, 28, 28}}, caption=name, save_as='name_label'},
            {type='flow', direction='horizontal', children={
              {type='label', style='bold_label', style_mods={font_color={28, 28, 28}}, caption={'', {'ltnm-gui.trains'}, ':'}, save_as='bold_labels.trains'},
              {type='label', style_mods={font_color={}}, caption=t.available_trains..'/'..t.num_trains, save_as='standard_labels.trains'}
            }},
            {type='flow', style_mods={vertical_align='center', horizontal_spacing=6}, save_as='status_flow', children={
              {type='label', style='bold_label', style_mods={font_color={28, 28, 28}}, caption={'', {'ltnm-gui.status'}, ':'}, save_as='bold_labels.status'}
            }}
          }}
        }}
      })
      local statuses = {}
      for _,station_id in ipairs(t.stations) do
        local status = data.stations[station_id].status
        statuses[status.name] = (statuses[status.name] or 0) + status.count
      end
      local status_flow = elems.status_flow
      for status_name, status_count in pairs(statuses) do
        local output = gui.build(status_flow, {gui.templates.status_indicator('indicator', status_name, status_count)})
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
        _,_,new_selection = string_find(gui_data.depots.buttons_scroll_pane.children[1].name, '^ltnm_depot_button_(.*)$')
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
    local trains_table = gui_data.depots.trains_table
    trains_table.clear()

    local depot_data = gui_data.depots
    -- retrieve train array and iteration settings
    local depot = data.depots[depot_data.selected]
    local active_sort = depot_data.active_sort
    local trains = depot.trains[active_sort]
    if active_sort == 'status' then
      trains = trains[player.index]
    end
    local sort_value = depot_data['sort_'..active_sort]
    local start = sort_value and 1 or #trains
    local finish = sort_value and #trains or 1
    local delta = sort_value and 1 or -1
    for i=start,finish,delta do
      local train_id = trains[i]
      local train = data.trains[train_id]
      -- build GUI structure
      local elems = gui.build(trains_table, {
        {type='label', style='hoverable_bold_label', style_mods={top_margin=-2}, caption=train.composition},
        {type='flow', style_mods={horizontally_stretchable=true, vertical_spacing=-1, top_padding=-2, bottom_padding=-1}, direction='vertical',
          save_as='status_flow'},
        {type='frame', style='ltnm_dark_content_frame_in_light_frame', children={
          {type='scroll-pane', style='ltnm_train_slot_table_scroll_pane', children={
            {type='table', style='ltnm_small_slot_table', column_count=4, save_as='contents_table'}
          }}
        }}
      })
      -- train status
      local status_flow_add = elems.status_flow.add
      for _,t in ipairs(train.status[player.index]) do
        status_flow_add{type='label', style=t[1], caption=t[2]}
      end
      -- contents table
      if train.shipment then
        local contents_table = elems.contents_table
        for name,count in pairs(train.shipment) do
          contents_table.add{type='sprite-button', style='ltnm_small_slot_button_green', sprite=string_gsub(name, ',', '/'), number=count}
        end
      end
    end
    -- local num_children = #trains_table.children
    -- if num_children == 0 then
    --   gui.build(gui_data.depots.trains_scrollpane, {
    --     {type='flow', style_mods={horizontally_stretchable=true, vertically_stretchable=true, horizontal_align='center', vertical_align='center'}, children={
    --       {type='label', caption={'ltnm-gui.select-a-depot-to-show-trains'}}
    --     }}
    --   })
    -- end
  end

  -- STATIONS LIST
  if state_changes.stations_list then
    local stations_table = gui_data.stations.table
    stations_table.clear()

    local stations = data.stations
    for id,t in pairs(stations) do
      if not t.isDepot then -- don't include depots in the stations list
        -- build GUI structure
        local elems = gui.build(stations_table, {
          {type='label', style='hoverable_bold_label', caption=t.entity.backer_name},
          {type='label', caption=t.network_id},
          gui.templates.status_indicator('indicator', t.status.name, t.status.count),
          -- items
          {type='frame', style='ltnm_dark_content_frame_in_light_frame', save_as='provided_requested_frame', children={
            {type='scroll-pane', style='ltnm_station_provided_requested_slot_table_scroll_pane', save_as='provided_requested_scroll_pane', children={
              {type='table', style='ltnm_small_slot_table', column_count=5, save_as='provided_requested_table'}
            }}
          }},
          {type='frame', style='ltnm_dark_content_frame_in_light_frame', save_as='shipments_frame', children={
            {type='scroll-pane', style='ltnm_station_shipments_slot_table_scroll_pane', save_as='shipments_scroll_pane', children={
              {type='table', style='ltnm_small_slot_table', column_count=4, save_as='shipments_table'}
            }}
          }},
          -- control signals
          {type='frame', style='ltnm_dark_content_frame_in_light_frame', save_as='signals_frame', children={
            {type='scroll-pane', style='ltnm_station_shipments_slot_table_scroll_pane', save_as='signals_scroll_pane', children={
              {type='table', style='ltnm_small_slot_table', column_count=4, save_as='signals_table'}
            }}
          }}
        })

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
        provided_requested_rows = math.ceil(provided_requested_rows / 6) -- number of columns

        -- add active shipments
        local shipments = t.activeDeliveries
        table_add = elems.shipments_table.add
        local shipments_rows = 0
        for i=1,#shipments do
          local shipment = data.trains[shipments[i]].shipment
          for name,count in pairs(shipment) do
            shipments_rows = shipments_rows + 1
            table_add{type='sprite-button', style='ltnm_small_slot_button_dark_grey', sprite=string_gsub(name, ',', '/'), number=count}
          end
        end
        shipments_rows = math.ceil(shipments_rows / 4) -- number of columns

        -- add control signals
        local signals = t.input.get_merged_signals()
        table_add = elems.signals_table.add
        local signals_rows = 0
        for i=1,#signals do
          local signal = signals[i]
          local name = signal.signal.name
          if name ~= 'ltn-network-id' and string_find(name, '^ltn%-') then
            signals_rows = signals_rows + 1
            table_add{type='sprite-button', style='ltnm_small_slot_button_dark_grey', sprite='virtual-signal/'..name, number=signal.count,
              tooltip={'virtual-signal-name.'..name}}.enabled = false
          end
        end
        signals_rows = math.ceil(signals_rows / 4) -- number of columns

        local num_rows = math.max(provided_requested_rows, shipments_rows, signals_rows)

        -- set scroll pane properties
        if provided_requested_rows > 3 then
          elems.provided_requested_frame.style.right_margin = -12
          elems.shipments_frame.style = 'ltnm_dark_content_frame_in_light_frame_no_left'
        end
        if shipments_rows > 3 then
          elems.shipments_frame.style.right_margin = -12
          elems.signals_frame.style = 'ltnm_dark_content_frame_in_light_frame_no_left'
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

  -- INVENTORY CONTENTS
  -- also not used externally
  if state_changes.inventory_contents then
    local inventory = data.inventory
    local inventory_gui_data = gui_data.inventory
    inventory_gui_data.material_buttons = {}
    inventory_gui_data.contents = {}
    local buttons = inventory_gui_data.material_buttons
    for type,color in pairs{provided='green', requested='red', in_transit='blue'} do
      -- combine materials (temporary until network filters become a thing)
      local combined_materials = {}
      for _,materials in pairs(inventory[type]) do
        combined_materials = util.add_materials(materials, combined_materials)
      end
      -- add combined materials to the GUI table (also temporary)
      inventory_gui_data.contents[type] = combined_materials
      -- add to table
      local table = inventory_gui_data[type..'_table']
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
    state_changes.selected_material = state_changes.selected_material or inventory_gui_data.selected
    inventory_gui_data.selected = nil
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
    local contents = inventory_gui_data.contents
    for _,type in ipairs{'provided', 'requested', 'in_transit'} do
      info_pane[type..'_value'].caption = util.comma_value(contents[type][inventory_gui_data.selected] or 0)
    end

    -- set up scroll pane and locals
    local locations_pane = inventory_gui_data.locations_scroll_pane
    locations_pane.clear()
    local pane_add = locations_pane.add
    local locations = data.material_locations[state_changes.selected_material]

    -- stations
    local stations = data.stations
    local station_ids = locations.stations
    if #station_ids > 0 then
      gui.build(locations_pane, {
        {type='flow', children={
          {type='label', style='caption_label', caption={'ltnm-gui.stations'}},
          {template='pushers.horizontal'}
        }}
      })
      pane_add{type='line', style='ltnm_material_locations_line', direction='horizontal'}
      for i=1,#station_ids do
        local station = stations[station_ids[i]]
        if station then
          local materials_table = gui.build(locations_pane, {
            {type='flow', direction='vertical', children={
              {type='label', style='bold_label', caption=station.entity.backer_name},
              {type='frame', style='ltnm_dark_content_frame_in_light_frame', children={
                {type='scroll-pane', style='ltnm_material_location_slot_table_scroll_pane', children={
                  {type='table', style='ltnm_small_slot_table', column_count=8, save_as='table'}
                }}
              }}
            }}
          }).table
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
      gui.build(locations_pane, {
        {type='flow', children={
          {type='label', style='caption_label', caption={'ltnm-gui.trains'}},
          {template='pushers.horizontal'}
        }}
      })
      pane_add{type='line', style='ltnm_material_locations_line', direction='horizontal'}
      for i=1,#train_ids do
        local train = trains[train_ids[i]]
        if train then
          local materials_table = gui.build(locations_pane, {
            {type='flow', direction='vertical', children={
              {type='label', style='bold_label', caption=train.from..'  ->  '..train.to},
              {type='frame', style='ltnm_dark_content_frame_in_light_frame', children={
                {type='scroll-pane', style='ltnm_material_location_slot_table_scroll_pane', children={
                  {type='table', style='ltnm_small_slot_table', column_count=8, save_as='table'}
                }}
              }}
            }}
          }).table
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

  -- HISTORY
  if state_changes.history then
    local history = data.history
    local history_table = gui_data.history.table
    history_table.clear()

    for i=1,#history do
      local entry = history[i]
      local table_add = gui.build(history_table, {
        {type='label', style='bold_label', style_mods={width=140}, caption=entry.depot},
        {type='flow', style_mods={horizontally_stretchable=true, vertical_spacing=-1, top_padding=-2, bottom_padding=-1}, direction='vertical', children={
          {type='label', style='bold_label', caption=entry.from},
          {type='flow', children={
            {type='label', style='caption_label', caption='->'},
            {type='label', style='bold_label', caption=entry.to}
          }}
        }},
        {type='label', style_mods={right_margin=8}, caption=entry.runtime and util.ticks_to_time(entry.runtime) or 'N/A'},
        {type='frame', style='ltnm_dark_content_frame_in_light_frame', children={
          {type='scroll-pane', style='ltnm_train_slot_table_scroll_pane', children={
            {type='table', style='ltnm_small_slot_table', column_count=4, save_as='table'}
          }}
        }}
      }).table.add
      for name,count in pairs(entry.actual_shipment or entry.shipment) do
        table_add{type='sprite-button', style='ltnm_small_slot_button_dark_grey', sprite=string_gsub(name, ',', '/'), number=count}
      end
    end
  end
end

return self