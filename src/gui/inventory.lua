-- -------------------------------------------------------------------------------------------------------------------------------------------------------------
-- INVENTORY GUI
-- A tab of the main GUI

-- dependencies
local constants = require('scripts.constants')
local event = require('__RaiLuaLib__.lualib.event')
local gui = require('__RaiLuaLib__.lualib.gui')
local util = require('scripts.util')

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
        flow_add{type='label', style=t[1], caption=t[2], tooltip=t[3]}
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
        main_gui.update(game.get_player(e.player_index), player_table, {inventory_contents=true})
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
        main_gui.update(game.get_player(e.player_index), player_table, {inventory_contents=true})
      end
    }
  }
}

-- -----------------------------------------------------------------------------

inventory_gui.base_template = {type='flow', style_mods={horizontal_spacing=12}, mods={visible=false}, save_as='tabbed_pane.contents.inventory', children={
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
}}

return inventory_gui