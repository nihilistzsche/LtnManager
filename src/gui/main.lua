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
local bit32_btest = bit32.btest
local string_find = string.find
local string_gsub = string.gsub
local string_lower = string.lower
local string_match = string.match

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
  close_button = {type='sprite-button', style='ltnm_frame_action_button', sprite='utility/close_white', hovered_sprite='utility/close_black',
    clicked_sprite='utility/close_black', mouse_button_filter={'left'}, handlers='main.titlebar.close_button', save_as='titlebar.close_button'},
  mock_frame_tab = {type='button', style='ltnm_mock_frame_tab', mouse_button_filter={'left'}, handlers='main.titlebar.frame_tab'},
  status_indicator = function(name, color, value)
    return {type='flow', style_mods={vertical_align='center'}, children={
      {type='sprite', style='ltnm_status_icon', sprite='ltnm_indicator_'..color, save_as=name..'_circle'},
      {type='label', caption=value, save_as=name..'_label'}
    }}
  end,
  inventory = {
    slot_table_with_label = function(name, rows)
      rows = rows or 4
      return {type='flow', style_mods={vertical_spacing=8, top_padding=4}, direction='vertical', children={
        {type='label', style='caption_label', caption={'ltnm-gui.'..string_gsub(name, '_', '-')}},
        {type='frame', style='ltnm_dark_content_frame_in_light_frame', children={
          {type='scroll-pane', style='ltnm_slot_table_scroll_pane', style_mods={height=rows*40}, vertical_scroll_policy='always', children={
            {type='table', style='ltnm_inventory_slot_table', column_count=10, save_as='inventory.'..name..'_table'}
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
    end,
    small_slot_table_with_label = function(parent, labels, materials, translations)
      local elems = gui.build(parent, {
        {type='flow', direction='vertical', children={
          {type='flow', save_as='labels_flow'},
          {type='frame', style='ltnm_dark_content_frame_in_light_frame', children={
            {type='scroll-pane', style='ltnm_material_location_slot_table_scroll_pane', vertical_scroll_policy='always', children={
              {type='table', style='ltnm_materials_in_location_slot_table', column_count=9, save_as='table'}
            }}
          }}
        }}
      })
      -- populate labels
      local flow = elems.labels_flow
      local flow_add = flow.add
      for _,t in ipairs(labels) do
        flow_add{type='label', style=t[1], caption=t[2], tooltip=t[3]}
        flow_add{type='empty-widget'}.style.horizontally_stretchable = true
      end
      flow.children[#flow.children].destroy()
      -- populate materials
      slot_style = slot_style or 'dark_grey'
      local table_add = elems.table.add
      local i = 0
      for _,t in ipairs(materials) do
        local style = 'ltnm_small_slot_button_'..t[1]
        for name,count in pairs(t[2]) do
          i = i + 1
          table_add{type='sprite-button', name='ltnm_material_button_'..i, style=style, sprite=string_gsub(name, ',', '/'), number=count,
            tooltip=translations[name]}
        end
      end
      return elems
    end
  }
}

gui.handlers:extend{main={
  window = {
    on_gui_closed = function(e)
      self.destroy(game.get_player(e.player_index), global.players[e.player_index])
    end
  },
  titlebar = {
    frame_tab = {
      on_gui_click = function(e)
        local name = e.default_tab or string_gsub(e.element.caption[1], 'ltnm%-gui%.', '')
        self.update_active_tab(game.get_player(e.player_index), global.players[e.player_index], name)
      end
    },
    pin_button = {
      on_gui_click = function(e)
        
      end
    },
    refresh_button = {
      on_gui_click = function(e)
        if e.shift then
          if event.is_enabled('auto_refresh', e.player_index) then
            event.disable('auto_refresh', e.player_index)
            e.element.style = 'ltnm_frame_action_button'
          else
            event.enable('auto_refresh', e.player_index)
            e.element.style = 'ltnm_active_frame_action_button'
          end
        else
          self.update_active_tab(game.get_player(e.player_index), global.players[e.player_index])
        end
      end
    },
    close_button = {
      on_gui_click = function(e)
        self.destroy(game.get_player(e.player_index), global.players[e.player_index])
      end
    },
  },
  material_button = {
    on_gui_click = function(e)
      local player_table = global.players[e.player_index]
      local on_inventory_tab = player_table.gui.main.tabbed_pane.selected == 'inventory'
      self.update(game.get_player(e.player_index), player_table, {
        active_tab = (not on_inventory_tab) and 'inventory',
        inventory_contents = (not on_inventory_tab) and true,
        selected_material = string_gsub(e.element.sprite, '/', ',')}
      )
    end
  },
  ['ltnm-search'] = function(e)
    local player_table = global.players[e.player_index]
    local gui_data = player_table.gui.main
    local active_tab = gui_data.tabbed_pane.selected
    if active_tab == 'inventory' then
      -- focus textfield
      gui_data.inventory.search_textfield.focus()
      -- select all text if on default
      gui.handlers.main.inventory.search_textfield.on_gui_click{player_index=e.player_index, element=gui_data.inventory.search_textfield}
    end
  end,
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
          -- update styles
          gui_data[gui_data.active_sort..'_sort_checkbox'].style = 'ltnm_sort_checkbox_inactive'
          e.element.style = 'ltnm_sort_checkbox_active'
          -- reset the checkbox value and switch active sort
          e.element.state = not e.element.state
          gui_data.active_sort = clicked_type
        else
          -- update the state in global
          gui_data['sort_'..clicked_type] = e.element.state
        end
        -- update GUI contents
        self.update(game.get_player(e.player_index), player_table, {depot_trains=true})
      end
    }
  },
  stations = {
    sort_checkbox = {
      on_gui_checked_state_changed = function(e)
        local _,_,clicked_type = string_find(e.element.name, '^ltnm_sort_station_(.-)$')
        local player_table = global.players[e.player_index]
        local gui_data = player_table.gui.main.stations
        if gui_data.active_sort ~= clicked_type then
          -- update styles
          gui_data[gui_data.active_sort..'_sort_checkbox'].style = 'ltnm_sort_checkbox_inactive'
          e.element.style = 'ltnm_sort_checkbox_active'
          -- reset the checkbox value and switch active sort
          e.element.state = not e.element.state
          gui_data.active_sort = clicked_type
        else
          -- update the state in global
          gui_data['sort_'..clicked_type] = e.element.state
        end
        -- update GUI contents
        self.update(game.get_player(e.player_index), player_table, {stations_list=true})
      end
    }
  },
  inventory = {
    search_textfield = {
      on_gui_text_changed = function(e)
        local player_table = global.players[e.player_index]
        local gui_data = player_table.gui.main.inventory
        gui_data.search_query = e.text
        self.update(game.get_player(e.player_index), player_table, {inventory_contents=true})
      end,
      on_gui_click = function(e)
        -- select all text if it is the default
        if e.element.text == global.players[e.player_index].dictionary.gui.translations.search then
          e.element.select_all()
        end
      end
    },
    network_id_textfield = {
      on_gui_text_changed = function(e)
        local player_table = global.players[e.player_index]
        local gui_data = player_table.gui.main.inventory
        local input = tonumber(e.text) or -1
        gui_data.selected_network_id = input
        self.update(game.get_player(e.player_index), player_table, {inventory_contents=true})
      end
    }
  },
  history = {
    sort_checkbox = {
      on_gui_checked_state_changed = function(e)
        local _,_,clicked_type = string_find(e.element.name, '^ltnm_sort_history_(.-)$')
        local player_table = global.players[e.player_index]
        local gui_data = player_table.gui.main.history
        if gui_data.active_sort ~= clicked_type then
          -- update styles
          gui_data[gui_data.active_sort..'_sort_checkbox'].style = 'ltnm_sort_checkbox_inactive'
          e.element.style = 'ltnm_sort_checkbox_active'
          -- reset the checkbox value and switch active sort
          e.element.state = not e.element.state
          gui_data.active_sort = clicked_type
        else
          -- update the state in global
          gui_data['sort_'..clicked_type] = e.element.state
        end
        -- update GUI contents
        self.update(game.get_player(e.player_index), player_table, {history=true})
      end
    },
    delete_button = {
      on_gui_click = function(e)
        -- remove from current data
        global.data.history = {}
        global.working_data.history = {}
        local sorted_history = global.data.sorted_history
        for key,_ in pairs(sorted_history) do
          sorted_history[key] = {}
        end
        self.update(game.get_player(e.player_index), global.players[e.player_index], {history=true})
      end
    }
  }
}}

-- -----------------------------------------------------------------------------
-- GUI MANAGEMENT

function self.create(player, player_table)
  -- profiler.Start()
  -- create base GUI structure
  local gui_data = gui.build(player.gui.screen, {
    {type='frame', style='ltnm_empty_frame', direction='vertical', handlers='main.window', save_as='window', children={
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
          {type='sprite-button', style='ltnm_frame_action_button', sprite='ltnm_pin_white', hovered_sprite='ltnm_pin_black', clicked_sprite='ltnm_pin_black',
            tooltip={'ltnm-gui.keep-open'}, mouse_button_filter={'left'}, handlers='main.titlebar.pin_button', save_as='titlebar.pin_button'},
          {type='sprite-button', style='ltnm_frame_action_button', sprite='ltnm_refresh_white', hovered_sprite='ltnm_refresh_black',
            clicked_sprite='ltnm_refresh_black', tooltip={'ltnm-gui.refresh-button-tooltip'}, mouse_button_filter={'left'},
            handlers='main.titlebar.refresh_button', save_as='titlebar.refresh_button'},
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
            {type='checkbox', name='ltnm_sort_station_name', style='ltnm_sort_checkbox_active', style_mods={left_margin=-4}, caption={'ltnm-gui.station-name'},
              state=true, handlers='main.stations.sort_checkbox', save_as='stations.name_sort_checkbox'},
            {template='pushers.horizontal'},
            {type='checkbox', name='ltnm_sort_station_network_id', style='ltnm_sort_checkbox_inactive', style_mods={horizontal_align='center', width=24},
              state=true, caption={'ltnm-gui.id'}, handlers='main.stations.sort_checkbox', save_as='stations.network_id_sort_checkbox'},
            {type='checkbox', name='ltnm_sort_station_status', style='ltnm_sort_checkbox_inactive', style_mods={horizontal_align='center', width=34},
              state=true, handlers='main.stations.sort_checkbox', save_as='stations.status_sort_checkbox'},
            {type='label', style='caption_label', style_mods={width=180}, caption={'ltnm-gui.provided-requested'}},
            {type='label', style='caption_label', style_mods={width=144}, caption={'ltnm-gui.shipments'}},
            {type='label', style='caption_label', style_mods={width=144}, caption={'ltnm-gui.control-signals'}},
            {type='empty-widget', style_mods={width=8}}
            -- {type='sprite-button', style='tool_button', sprite='ltnm_filter', tooltip={'ltnm-gui.station-filters-tooltip'}}
          }},
          {type='scroll-pane', style='ltnm_blank_scroll_pane', direction='vertical', vertical_scroll_policy='always', save_as='stations.scroll_pane', children={
            {type='table', style='ltnm_stations_table', style_mods={vertically_stretchable=true}, column_count=6, save_as='stations.table'}
          }}
        }},
        -- INVENTORY
        {type='flow', style_mods={horizontal_spacing=12}, mods={visible=false}, save_as='tabbed_pane.contents.inventory', children={
          -- left column
          {type='frame', style='ltnm_light_content_frame', direction='vertical', children={
            -- toolbar
            {type='frame', style='ltnm_toolbar_frame', style_mods={height=nil}, direction='horizontal', children={
              {type='textfield', text=player_table.dictionary.gui.translations.search, lose_focus_on_confirm=true, handlers='main.inventory.search_textfield',
                save_as='inventory.search_textfield'},
              {template='pushers.horizontal'},
              {type='label', style='caption_label', caption={'ltnm-gui.network-id'}},
              {type='textfield', style='short_number_textfield', text='-1', lose_focus_on_confirm=true, numeric=true,
                allow_negative=true, handlers='main.inventory.network_id_textfield', save_as='inventory.network_id_textfield'},
              -- {type='sprite-button', style='tool_button', sprite='ltnm_filter', tooltip={'ltnm-gui.network-selection-dialog'}, mods={enabled=false}}
            }},
            -- inventory tables
            {type='flow', style_mods={padding=10, top_padding=4}, direction='vertical', children={
              gui.templates.inventory.slot_table_with_label('provided', 6),
              gui.templates.inventory.slot_table_with_label('requested', 3),
              gui.templates.inventory.slot_table_with_label('in_transit', 2)
            }}
          }},
          -- right column
          {type='frame', style='ltnm_light_content_frame', direction='vertical', children={
            -- item information
            {type='frame', style='ltnm_light_content_frame_in_light_frame', style_mods={horizontally_stretchable=true, vertically_stretchable=true},
              direction='vertical', children={
                {type='frame', style='ltnm_item_info_toolbar_frame', direction='vertical', children={
                  -- icon and name
                  {type='flow', style_mods={vertical_align='center'}, children={
                    {type='sprite', style='ltnm_material_icon', sprite='item-group/intermediate-products', save_as='inventory.info_pane.icon'},
                    {type='label', style='caption_label', style_mods={left_margin=2}, caption={'ltnm-gui.choose-an-item'}, save_as='inventory.info_pane.name'}
                  }},
                  -- info
                  gui.templates.inventory.label_with_value('provided', {'ltnm-gui.provided'}, 0),
                  gui.templates.inventory.label_with_value('requested', {'ltnm-gui.requested'}, 0),
                  gui.templates.inventory.label_with_value('in_transit', {'ltnm-gui.in-transit'}, 0)
                }},
                {type='scroll-pane', style='ltnm_material_locations_scroll_pane', style_mods={horizontally_stretchable=true, vertically_stretchable=true},
                  vertical_scroll_policy='always', save_as='inventory.locations_scroll_pane'}
              }
            }

          }}
        }},
        -- HISTORY
        {type='frame', style='ltnm_light_content_frame', direction='vertical', mods={visible=false}, save_as='tabbed_pane.contents.history', children={
          -- toolbar
          {type='frame', style='ltnm_toolbar_frame', children={
            {type='checkbox', name='ltnm_sort_history_depot', style='ltnm_sort_checkbox_inactive', state=true, style_mods={width=140, left_margin=8},
              caption={'ltnm-gui.depot'}, handlers='main.history.sort_checkbox', save_as='history.depot_sort_checkbox'},
            {type='checkbox', name='ltnm_sort_history_route', style='ltnm_sort_checkbox_inactive', state=true, caption={'ltnm-gui.route'},
              handlers='main.history.sort_checkbox', save_as='history.route_sort_checkbox'},
            {template='pushers.horizontal'},
            {type='checkbox', name='ltnm_sort_history_network_id', style='ltnm_sort_checkbox_inactive', style_mods={right_margin=8}, state=true,
              caption={'ltnm-gui.id'}, handlers='main.history.sort_checkbox', save_as='history.network_id_sort_checkbox'},
            {type='checkbox', name='ltnm_sort_history_runtime', style='ltnm_sort_checkbox_inactive', style_mods={right_margin=8}, state=true,
              caption={'ltnm-gui.runtime'}, handlers='main.history.sort_checkbox', save_as='history.runtime_sort_checkbox'},
            {type='checkbox', name='ltnm_sort_history_finished', style='ltnm_sort_checkbox_active', style_mods={right_margin=8}, state=false,
              caption={'ltnm-gui.finished'}, handlers='main.history.sort_checkbox', save_as='history.finished_sort_checkbox'},
            {type='label', style='caption_label', style_mods={width=124}, caption={'ltnm-gui.shipment'}},
            {type='sprite-button', style='red_icon_button', sprite='utility/trash', tooltip={'ltnm-gui.clear-history'},
              handlers='main.history.delete_button', save_as='history.delete_button'}
          }},
          -- listing
          {type='scroll-pane', style='ltnm_blank_scroll_pane', style_mods={horizontally_stretchable=true, vertically_stretchable=true},
            vertical_scroll_policy='always', save_as='history.pane', children={
              {type='table', style='ltnm_rows_table', style_mods={vertically_stretchable=true}, column_count=6, save_as='history.table'}
            }
          }
        }},
        -- ALERTS
        {type='empty-widget', mods={visible=false}, save_as='tabbed_pane.contents.alerts'}
      }}
    }}
  })

  -- other handlers
  event.enable_group('gui.main.material_button', player.index, 'ltnm_material_button_')
  event.enable('gui.main.ltnm-search', player.index)

  -- default settings
  gui_data.tabbed_pane.selected = 'depots'

  gui_data.depots.active_sort = 'composition'
  gui_data.depots.sort_composition = true
  gui_data.depots.sort_status = true

  gui_data.stations.active_sort = 'name'
  gui_data.stations.sort_name = true
  gui_data.stations.sort_network_id = true
  gui_data.stations.sort_status = true

  gui_data.inventory.selected_network_id = -1
  gui_data.inventory.search_query = ''

  gui_data.history.active_sort = 'finished'
  gui_data.history.sort_depot = true
  gui_data.history.sort_route = true
  gui_data.history.sort_runtime = true
  gui_data.history.sort_finished = false

  -- dragging and centering
  gui_data.titlebar.drag_handle.drag_target = gui_data.window
  gui_data.window.force_auto_center()

  -- opened
  -- player.opened = gui_data.window

  -- save data to global
  player_table.gui.main = gui_data

  -- set initial contents
  self.update_active_tab(player, player_table)
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
  local material_translations = player_table.dictionary.materials.translations

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
        local i = 0
        for name,count in pairs(train.shipment) do
          i = i + 1
          contents_table.add{type='sprite-button', name='ltnm_material_button_'..i, style='ltnm_small_slot_button_dark_grey',
            sprite=string_gsub(name, ',', '/'), number=count}
        end
      end
    end
  end

  -- STATIONS LIST
  if state_changes.stations_list then
    local stations_table = gui_data.stations.table
    stations_table.clear()

    local active_sort = gui_data.stations.active_sort
    local sort_value = gui_data.stations['sort_'..active_sort]
    local stations = data.stations
    local sorted_stations = data.sorted_stations[active_sort]
    local start = sort_value and 1 or #sorted_stations
    local finish = sort_value and #sorted_stations or 1
    local delta = sort_value and 1 or -1
    for i=start,finish,delta do
      local t = stations[sorted_stations[i]]
      -- build GUI structure
      local elems = gui.build(stations_table, {
        {type='label', style='hoverable_bold_label', style_mods={horizontally_stretchable=true}, caption=t.entity.backer_name},
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
      local mi = 0
      for key,color in pairs{provided='green', requested='red'} do
        local materials = t[key]
        if materials then
          for name,count in pairs(materials) do
            mi = mi + 1
            provided_requested_rows = provided_requested_rows + 1
            table_add{type='sprite-button', name='ltnm_material_button_'..mi, style='ltnm_small_slot_button_'..color, sprite=string_gsub(name, ',', '/'),
              number=count}
          end
        end
      end
      provided_requested_rows = math.ceil(provided_requested_rows / 6) -- number of columns

      -- add active shipments
      local shipments = t.activeDeliveries
      table_add = elems.shipments_table.add
      local shipments_rows = 0
      local mi = 0
      for i=1,#shipments do
        local shipment = data.trains[shipments[i]].shipment
        for name,count in pairs(shipment) do
          mi = mi + 1
          shipments_rows = shipments_rows + 1
          table_add{type='sprite-button', name='ltnm_material_button_'..mi, style='ltnm_small_slot_button_dark_grey', sprite=string_gsub(name, ',', '/'),
            number=count}
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

  -- INVENTORY CONTENTS
  if state_changes.inventory_contents then
    local inventory = data.inventory
    local inventory_gui_data = gui_data.inventory
    local selected_network_id = inventory_gui_data.selected_network_id
    inventory_gui_data.material_buttons = {}
    inventory_gui_data.contents = {}
    local buttons = inventory_gui_data.material_buttons
    for type,color in pairs{provided='green', requested='red', in_transit='blue'} do
      -- combine contents of each matching network
      local combined_materials = {}
      for network_id,materials in pairs(inventory[type]) do
        if bit32_btest(network_id, selected_network_id) then
          combined_materials = util.add_materials(materials, combined_materials)
        end
      end
      -- filter by material name
      local query = string_lower(inventory_gui_data.search_textfield.text)
      if query ~= '' and query ~= string_lower(player_table.dictionary.gui.translations.search) then
        for name,_ in pairs(combined_materials) do
          if not string_match(material_translations[name], query) then
            combined_materials[name] = nil
          end
        end
      end
      -- add combined materials to the GUI table (also temporary)
      inventory_gui_data.contents[type] = combined_materials
      -- add to table
      local table = inventory_gui_data[type..'_table']
      table.clear()
      local add = table.add
      local elems = {}
      local i = 0
      for name,count in pairs(combined_materials) do
        i = i + 1
        elems[name] = add{type='sprite-button', name='ltnm_material_button_'..i, style='ltnm_slot_button_'..color,
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

    -- material counts
    local contents = inventory_gui_data.contents
    for _,type in ipairs{'provided', 'requested', 'in_transit'} do
      info_pane[type..'_value'].caption = util.comma_value(contents[type][inventory_gui_data.selected] or 0)
    end

    -- set up scroll pane and locals
    local locations_pane = inventory_gui_data.locations_scroll_pane
    locations_pane.clear()
    local locations = data.material_locations[state_changes.selected_material]
    local location_template = gui.templates.inventory.small_slot_table_with_label

    -- stations
    local empty = 0
    local selected_network_id = inventory_gui_data.selected_network_id
    local stations = data.stations
    local station_ids = locations.stations
    if #station_ids > 0 then
      local label = locations_pane.add{type='label', style='ltnm_material_locations_label', caption={'ltnm-gui.stations'}}
      local table = locations_pane.add{type='table', style='ltnm_material_locations_table', column_count=1}
      for i=1,#station_ids do
        local station = stations[station_ids[i]]
        if bit32_btest(station.network_id, selected_network_id) then
          local materials = {}
          for mode,color in pairs{provided='green', requested='red'} do
            local contents = station[mode]
            if contents then
              materials[#materials+1] = {color, contents}
            end
          end
          location_template(table, {{'bold_label', station.entity.backer_name}}, materials, {})
        end
      end
      if #table.children == 0 then
        empty = empty + 1
        label.destroy()
        table.destroy()
      end
    else
      empty = empty + 1
    end

    -- trains
    local trains = data.trains
    local train_ids = locations.trains
    if #train_ids > 0 then
      local label = locations_pane.add{type='label', style='ltnm_material_locations_label', caption={'ltnm-gui.trains'}}
      local table = locations_pane.add{type='table', style='ltnm_material_locations_table', column_count=1}
      for i=1,#train_ids do
        local train = trains[train_ids[i]]
        if bit32_btest(train.network_id, selected_network_id) then
          local materials = {}
          if train.shipment then
            materials = {{'blue', train.shipment}}
          end
          location_template(table, {{'bold_label', train.from}, {'caption_label', '->'}, {'bold_label', train.to}}, materials, {})
        end
      end
      if #table.children == 0 then
        empty = empty + 1
        label.destroy()
        table.destroy()
      end
    else
      empty = empty + 1
    end

    -- placeholder
    if empty == 2 then
      gui.build(locations_pane, {
        {type='flow', style_mods={horizontally_stretchable=true, vertically_stretchable=true, horizontal_align='center', vertical_align='center'}, children={
          {type='label', caption={'ltnm-gui.nothing-to-see-here'}}
        }}
      })
    end
  end

  -- HISTORY
  if state_changes.history then
    local history_table = gui_data.history.table
    history_table.clear()

    local active_sort = gui_data.history.active_sort
    local sort_value = gui_data.history['sort_'..active_sort]
    local sorted_history = data.sorted_history[active_sort]

    -- skip if the history is empty
    if #sorted_history > 0 then
      local history = data.history
      local start = sort_value and 1 or #sorted_history
      local finish = sort_value and #sorted_history or 1
      local delta = sort_value and 1 or -1

      for i=start,finish,delta do
        local entry = history[sorted_history[i]]
        local table_add = gui.build(history_table, {
          {type='label', style='bold_label', style_mods={width=140}, caption=entry.depot},
          {type='flow', style_mods={horizontally_stretchable=true, vertical_spacing=-1, top_padding=-2, bottom_padding=-1}, direction='vertical', children={
            {type='label', style='bold_label', caption=entry.from},
            {type='flow', children={
              {type='label', style='caption_label', caption='->'},
              {type='label', style='bold_label', caption=entry.to}
            }}
          }},
          {type='label', style_mods={right_margin=8, width=16, horizontal_align='right'}, caption=entry.network_id},
          {type='label', style_mods={right_margin=8, width=66, horizontal_align='right'}, caption=util.ticks_to_time(entry.runtime)},
          {type='label', style_mods={right_margin=8, width=64, horizontal_align='right'}, caption=util.ticks_to_time(entry.finished)},
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
end

function self.update_active_tab(player, player_table, name)
  name = name or player_table.gui.main.tabbed_pane.selected
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

return self