-- -------------------------------------------------------------------------------------------------------------------------------------------------------------
-- HISTORY GUI
-- A tab of the main GUI

-- dependencies
local constants = require('scripts.constants')
local event = require('__RaiLuaLib__.lualib.event')
local gui = require('__RaiLuaLib__.lualib.gui')
local util = require('scripts.util')

-- object
local history_gui = {}

-- -----------------------------------------------------------------------------
-- GUI DATA

gui.handlers:extend{
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
        main_gui.update(game.get_player(e.player_index), player_table, {history=true})
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
        main_gui.update(game.get_player(e.player_index), global.players[e.player_index], {history=true})
      end
    }
  },
}

-- -----------------------------------------------------------------------------

history_gui.base_template = {type='frame', style='ltnm_light_content_frame', direction='vertical', mods={visible=false}, save_as='tabbed_pane.contents.history', children={
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
}}

return history_gui