-- -------------------------------------------------------------------------------------------------------------------------------------------------------------
-- INVENTORY GUI
-- A tab of the main GUI

-- dependencies
local constants = require('scripts.constants')
local event = require('__RaiLuaLib__.lualib.event')
local gui = require('__RaiLuaLib__.lualib.gui')
local util = require('scripts.util')

-- locals
local bit32_btest = bit32.btest
local string_find = string.find
local string_gsub = string.gsub
local string_lower = string.lower
local string_match = string.match

-- object
local inventory_gui = {}

-- -----------------------------------------------------------------------------
-- GUI DATA

gui.templates:extend{
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
        flow_add{type='label', style=t[1], caption=t[2], tooltip=t[3], name=t[4]}
        flow_add{type='empty-widget'}.style.horizontally_stretchable = true
      end
      flow.children[#flow.children].destroy()
      -- populate materials
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

gui.handlers:extend{
  inventory = {
    search_textfield = {
      on_gui_text_changed = function(e)
        local player_table = global.players[e.player_index]
        local gui_data = player_table.gui.main.inventory
        gui_data.search_query = e.text
        UPDATE_MAIN_GUI(game.get_player(e.player_index), player_table, {inventory_contents=true})
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
        UPDATE_MAIN_GUI(game.get_player(e.player_index), player_table, {inventory_contents=true})
      end
    }
  }
}

-- -----------------------------------------------------------------------------
-- FUNCTIONS

function inventory_gui.update(player, player_table, state_changes, gui_data, data, material_translations)
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
        elems[name] = add{type='sprite-button', name='ltnm_material_button_'..i, style='ltnm_slot_button_'..color, sprite=string_gsub(name, ',', '/'),
          number=count, tooltip=material_translations[name]}
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
          location_template(
            table,
            {{'hoverable_bold_label', station.entity.backer_name, {'ltnm-gui.view-station-on-map'}, 'ltnm_view_station_'..station_ids[i]}},
            materials,
            material_translations
          )
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
          location_template(table, {{'hoverable_bold_label', train.from, {'ltnm-gui.view-station-on-map'}, 'ltnm_view_station_'..train.from_id},
            {'caption_label', '->'}, {'hoverable_bold_label', train.to, {'ltnm-gui.view-station-on-map'}, 'ltnm_view_station_'..train.to_id}}, materials,
            material_translations)
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
end

-- -----------------------------------------------------------------------------

inventory_gui.base_template = {type='flow', style_mods={horizontal_spacing=12}, mods={visible=false}, save_as='tabbed_pane.contents.inventory', children={
  -- left column
  {type='frame', style='ltnm_light_content_frame', direction='vertical', children={
    -- toolbar
    {type='frame', style='ltnm_toolbar_frame', style_mods={height=nil}, direction='horizontal', children={
      {type='textfield', lose_focus_on_confirm=true, handlers='inventory.search_textfield',
        save_as='inventory.search_textfield'},
      {template='pushers.horizontal'},
      {type='label', style='caption_label', caption={'ltnm-gui.network-id'}},
      {type='textfield', style='short_number_textfield', text='-1', lose_focus_on_confirm=true, numeric=true,
        allow_negative=true, handlers='inventory.network_id_textfield', save_as='inventory.network_id_textfield'},
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
}}

return inventory_gui