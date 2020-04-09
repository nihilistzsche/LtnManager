-- -------------------------------------------------------------------------------------------------------------------------------------------------------------
-- ALERTS GUI
-- A tab of the main GUI

-- dependencies
local constants = require('scripts.constants')
local event = require('__RaiLuaLib__.lualib.event')
local gui = require('__RaiLuaLib__.lualib.gui')
local util = require('scripts.util')

-- locals
local string_find = string.find
local string_gsub = string.gsub

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
        UPDATE_MAIN_GUI(game.get_player(e.player_index), player_table, {alerts_list=true})
      end
    },
    alert_type_label = {
      on_gui_click = {handler=function(e)
        local alert_id = string_gsub(e.element.name, 'ltnm_alert_type_label_', '')
        UPDATE_MAIN_GUI(game.get_player(e.player_index), global.players[e.player_index], {selected_alert=alert_id})
      end, gui_filters='ltnm_alert_type_label_', options={match_filter_strings=true}}
    }
  }
}

-- -----------------------------------------------------------------------------
-- FUNCTIONS

function alerts_gui.update(player, player_table, state_changes, gui_data, data, material_translations)
  -- ALERTS LIST
  if state_changes.alerts_list then
    local alerts_table = gui_data.alerts.table
    alerts_table.clear()

    local active_sort = gui_data.alerts.active_sort
    local sort_value = gui_data.alerts['sort_'..active_sort]
    local sorted_alerts = data.sorted_alerts[active_sort]

    -- skip if there are no alerts
    if #sorted_alerts > 0 then
      local alerts = data.alerts
      local start = sort_value and 1 or #sorted_alerts
      local finish = sort_value and #sorted_alerts or 1
      local delta = sort_value and 1 or -1

      local selected = tonumber(gui_data.alerts.selected or 0)

      for i=start,finish,delta do
        local alert_id = sorted_alerts[i]
        local entry = alerts[alert_id]
        local enabled = not (selected == alert_id)
        gui.build(alerts_table, {
          {type='label', name='ltnm_alert_time_label_'..alert_id, style='ltnm_hoverable_label', style_mods={width=64}, mods={ignored_by_interaction=true,
            enabled=enabled}, caption=util.ticks_to_time(entry.time)},
          {type='label', name='ltnm_alert_type_label_'..alert_id, style='ltnm_hoverable_bold_label', style_mods={width=212}, mods={enabled=enabled},
            caption={'ltnm-gui.alert-'..entry.type}}
        })
      end
    end
  end

  -- SELECTED ALERT
  if state_changes.selected_alert then
    local alert_id = state_changes.selected_alert
    local alert_data = data.alerts[tonumber(alert_id)]
    local alert_type = alert_data.type
    local pane = gui_data.alerts.info_pane
    pane.clear()

    local list_table = gui_data.alerts.table
    local previous_selection = gui_data.alerts.selected

    -- reset previous selection style
    if previous_selection then
      list_table['ltnm_alert_time_label_'..previous_selection].enabled = true
      list_table['ltnm_alert_type_label_'..previous_selection].enabled = true
    end

    -- set new selection style
    list_table['ltnm_alert_time_label_'..alert_id].enabled = false
    list_table['ltnm_alert_type_label_'..alert_id].enabled = false

    -- update title
    gui_data.alerts.info_title.caption = {'', {'ltnm-gui.alert-'..alert_type}, ' @ '..util.ticks_to_time(alert_data.time)}

    gui.build(pane, {
      -- description
      {type='frame', style='bordered_frame', children={
        {type='label', style='ltnm_paragraph_label', caption={'ltnm-gui.alert-'..alert_type..'-description'}}
      }},
      -- train
      {type='label', style='subheader_caption_label', caption={'ltnm-gui.train'}},
      {type='flow', direction='horizontal', children={

      }}
    })


    -- alert-specific stuff
    if alert_type == 'incomplete_pickup' then

    elseif alert_type == 'incomplete_delivery' then

    else
      
    end
    local breakpoint

    -- update selection in global
    gui_data.alerts.selected = state_changes.selected_alert
  end
end

-- -----------------------------------------------------------------------------

alerts_gui.base_template = {type='flow', style_mods={horizontal_spacing=12}, mods={visible=false}, save_as='tabbed_pane.contents.alerts', children={
  -- alerts list
  {type='frame', style='ltnm_light_content_frame', style_mods={width=312}, direction='vertical', children={
    {type='frame', style='ltnm_toolbar_frame', children={
      {type='checkbox', name='ltnm_sort_alerts_time', style='ltnm_sort_checkbox_active', style_mods={left_margin=8, width=64}, state=false,
        caption={'ltnm-gui.time'}, handlers='alerts.sort_checkbox', save_as='alerts.time_sort_checkbox'},
      {type='checkbox', name='ltnm_sort_alerts_type', style='ltnm_sort_checkbox_inactive', style_mods={width=220}, state=false,
        caption={'ltnm-gui.alert'}, handlers='alerts.sort_checkbox', save_as='alerts.type_sort_checkbox'}
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

return alerts_gui