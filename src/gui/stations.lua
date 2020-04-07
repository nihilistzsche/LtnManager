-- -------------------------------------------------------------------------------------------------------------------------------------------------------------
-- STATIONS GUI
-- A tab of the main GUI

-- dependencies
local constants = require('scripts.constants')
local event = require('__RaiLuaLib__.lualib.event')
local gui = require('__RaiLuaLib__.lualib.gui')
local util = require('scripts.util')

-- object
local stations_gui = {}

-- -----------------------------------------------------------------------------
-- GUI DATA

gui.handlers:extend{
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
        main_gui.update(game.get_player(e.player_index), player_table, {stations_list=true})
      end
    },
    open_station_button = {
      on_gui_click = function(e)
        local station_id = string_gsub(e.element.name, 'ltnm_open_station_', '')
        game.get_player(e.player_index).zoom_to_world(global.data.stations[tonumber(station_id)].entity.position, 0.5)
      end
    }
  }
}

-- -----------------------------------------------------------------------------

stations_gui.base_template = {type='frame', style='ltnm_light_content_frame', direction='vertical', mods={visible=false}, save_as='tabbed_pane.contents.stations', children={
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
  }},
  {type='scroll-pane', style='ltnm_blank_scroll_pane', direction='vertical', vertical_scroll_policy='always', save_as='stations.scroll_pane', children={
    {type='table', style='ltnm_stations_table', style_mods={vertically_stretchable=true, horizontally_stretchable=true}, column_count=6,
      save_as='stations.table'}
  }}
}}

return stations_gui