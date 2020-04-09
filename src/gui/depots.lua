-- -------------------------------------------------------------------------------------------------------------------------------------------------------------
-- DEPOTS GUI
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
local depots_gui = {}

-- -----------------------------------------------------------------------------
-- GUI DATA

gui.handlers:extend{
  depots = {
    depot_button = {
      on_gui_click = function(e)
        local _,_,name = string_find(e.element.name, '^ltnm_depot_button_(.*)$')
        UPDATE_MAIN_GUI(game.get_player(e.player_index), global.players[e.player_index], {selected_depot=name})
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
        UPDATE_MAIN_GUI(game.get_player(e.player_index), player_table, {depot_trains=true})
      end
    }
  }
}

-- -----------------------------------------------------------------------------
-- FUNCTIONS

function depots_gui.update(player, player_table, state_changes, gui_data, data, material_translations)
  -- DEPOT BUTTONS
  if state_changes.depot_buttons then
    local buttons_pane = gui_data.depots.buttons_scroll_pane
    -- delete old buttons and disable handler
    buttons_pane.clear()
    event.disable_group('gui.depots.depot_button', player.index)

    local buttons_data = {}

    local button_index = 0

    local button_style = table_size(data.depots) > 7 and 'ltnm_depot_button_for_scrollbar' or 'ltnm_depot_button'

    -- build all buttons as if they're inactive
    for name,t in pairs(data.depots) do
      button_index = button_index + 1
      local elems = gui.build(buttons_pane, {
        {type='button', name='ltnm_depot_button_'..name, style=button_style, handlers='depots.depot_button', save_as='button', children={
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
        {type='label', name='ltnm_open_train_'..train_id, style='hoverable_bold_label', style_mods={top_margin=-2}, caption=train.composition,
          tooltip={'ltnm-gui.open-train-gui'}},
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
            sprite=string_gsub(name, ',', '/'), number=count, tooltip=material_translations[name]}
        end
      end
    end
  end
end

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
        caption={'ltnm-gui.composition'}, state=true, handlers='depots.sort_checkbox', save_as='depots.composition_sort_checkbox'},
      {type='checkbox', name='ltnm_sort_train_status', style='ltnm_sort_checkbox_inactive', caption={'ltnm-gui.train-status'}, state=true,
        handlers='depots.sort_checkbox', save_as='depots.status_sort_checkbox'},
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