-- -------------------------------------------------------------------------------------------------------------------------------------------------------------
-- ALERTS GUI
-- A tab of the main GUI

-- dependencies
local constants = require('scripts.constants')
local event = require('__RaiLuaLib__.lualib.event')
local gui = require('__RaiLuaLib__.lualib.gui')
local util = require('scripts.util')

-- object
local alerts_gui = {}

-- -----------------------------------------------------------------------------
-- GUI DATA

gui.handlers:extend{
  alerts = {
    sort_checkbox = {
      on_gui_checked_state_changed = function(e)
        local _,_,clicked_type = string_find(e.element.name, '^ltnm_sort_alerts_(.-)$')
        local player_table = global.players[e.player_index]
        local gui_data = player_table.gui.main.alerts
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
        main_gui.update(game.get_player(e.player_index), player_table, {alerts_list=true})
      end
    },
    alert_type_label = {
      on_gui_click = {handler=function(e)
        local alert_id = string_gsub(e.element.name, 'ltnm_alert_type_label_', '')
        main_gui.update(game.get_player(e.player_index), global.players[e.player_index], {selected_alert=alert_id})
      end, gui_filters='ltnm_alert_type_label_', options={match_filter_strings=true}}
    }
  }
}

-- -----------------------------------------------------------------------------

alerts_gui.base_template = {type='flow', style_mods={horizontal_spacing=12}, mods={visible=false}, save_as='tabbed_pane.contents.alerts', children={
  -- alerts list
  {type='frame', style='ltnm_light_content_frame', style_mods={width=312}, direction='vertical', children={
    {type='frame', style='ltnm_toolbar_frame', children={
      {type='checkbox', name='ltnm_sort_alerts_time', style='ltnm_sort_checkbox_active', style_mods={left_margin=8, width=64}, state=false,
        caption={'ltnm-gui.time'}, handlers='main.alerts.sort_checkbox', save_as='alerts.time_sort_checkbox'},
      {type='checkbox', name='ltnm_sort_alerts_type', style='ltnm_sort_checkbox_inactive', style_mods={width=220}, state=false,
        caption={'ltnm-gui.alert'}, handlers='main.alerts.sort_checkbox', save_as='alerts.type_sort_checkbox'}
    }},
    {type='scroll-pane', style='ltnm_blank_scroll_pane', style_mods={vertically_stretchable=true}, children={
      {type='table', style='ltnm_rows_table', column_count=2, save_as='alerts.table'}
    }}
  }},
  -- information panel
  {type='frame', style='ltnm_light_content_frame', style_mods={horizontally_stretchable=true}, direction='vertical', children={
    {type='frame', style='ltnm_toolbar_frame', children={
      {type='label', style='subheader_caption_label', caption={'ltnm-gui.select-an-alert'}, save_as='alerts.info_title'},
      {template='pushers.horizontal'},
      {type='sprite-button', style='red_icon_button', sprite='utility/trash'}
    }},
    {type='scroll-pane', style='ltnm_blank_scroll_pane', style_mods={vertically_stretchable=true, padding=8}, save_as='alerts.info_pane'}
  }}
}}