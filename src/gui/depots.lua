-- -------------------------------------------------------------------------------------------------------------------------------------------------------------
-- DEPOTS GUI
-- A tab of the main GUI

-- dependencies
local constants = require('scripts.constants')
local event = require('__RaiLuaLib__.lualib.event')
local gui = require('__RaiLuaLib__.lualib.gui')
local util = require('scripts.util')

-- object
local depots_gui = {}

-- -----------------------------------------------------------------------------
-- GUI DATA

gui.handlers:extend{
  depots = {
    depot_button = {
      on_gui_click = function(e)
        local _,_,name = string_find(e.element.name, '^ltnm_depot_button_(.*)$')
        main_gui.update(game.get_player(e.player_index), global.players[e.player_index], {selected_depot=name})
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
        main_gui.update(game.get_player(e.player_index), player_table, {depot_trains=true})
      end
    },
    open_train_button = {
      on_gui_click = {handler=function(e)
        local train_id = string_gsub(e.element.name, 'ltnm_open_train_', '')
        game.get_player(e.player_index).opened = global.data.trains[tonumber(train_id)].main_locomotive
      end, gui_filters='ltnm_open_train_', options={match_filter_strings=true}}
    }
  }
}

-- -----------------------------------------------------------------------------

depots_gui.base_template = {type='flow', style_mods={horizontal_spacing=12}, mods={visible=false}, save_as='tabbed_pane.contents.depots', children={
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
}}

return depots_gui