-- -------------------------------------------------------------------------------------------------------------------------------------------------------------
-- MAIN GUI
-- The main GUI for the mod

-- dependencies
local event = require('lualib/event')
local gui = require('lualib/gui')

-- self object
local self = {}

-- -----------------------------------------------------------------------------
-- GUI DATA



-- -----------------------------------------------------------------------------
-- GUI MANAGEMENT

function self.create(player, player_table)
  local gui_data = gui.create(player.gui.screen, 'main', player.index,
    {type='frame', style='dialog_frame', direction='vertical', save_as='window', children={
      -- titlebar
      {type='flow', style='ltnm_titlebar_flow', direction='horizontal', children={
        {type='label', style='frame_title', caption={'mod-name.LtnManager'}},
        {type='empty-widget', style='ltnm_titlebar_drag_handle', save_as='drag_handle'}
      }},
      {type='frame', style='inside_deep_frame_for_tabs', children={
        {type='tabbed-pane', style='ltnm_tabbed_pane', children={
          -- depots tab
          {type='tab-and-content', tab={type='tab', caption={'ltnm-gui.depots'}}, content=
            {type='frame', style='ltnm_scroll_pane_frame', direction='vertical', children={
              {type='scroll-pane', style='ltnm_depots_scroll_pane', direction='vertical', children={
                {type='frame', style={name='ltnm_depot_frame', height=308, horizontally_stretchable=true}, direction='vertical', children={
                  {type='label', style='caption_label', caption='Depot'}
                }}
              }}
            }}
          },
          -- stations tab
          {type='tab-and-content', tab={type='tab', caption={'ltnm-gui.stations'}}, content=
            {type='empty-widget'}
          },
          -- inventory tab
          {type='tab-and-content', tab={type='tab', caption={'ltnm-gui.inventory'}}, content=
            {type='flow', style={left_padding=8}, direction='vertical', children={
              {type='label', style='caption_label', caption={'ltnm-gui.available'}},
              {type='frame', style={name='ltnm_icon_slot_table_frame', height=160}, children={
                {type='scroll-pane', style='ltnm_icon_slot_table_scroll_pane', vertical_scroll_policy='always', children={
                  {type='table', style='ltnm_icon_slot_table', column_count=10, save_as='available_table'}
                }},
              }},
              {type='label', style='caption_label', caption={'ltnm-gui.requested'}},
              {type='frame', style={name='ltnm_icon_slot_table_frame', height=160}, children={
                {type='scroll-pane', style='ltnm_icon_slot_table_scroll_pane', vertical_scroll_policy='always', children={
                  {type='table', style='ltnm_icon_slot_table', column_count=10, save_as='requested_table'}
                }},
              }},
              {type='label', style='caption_label', caption={'ltnm-gui.in-transit'}},
              {type='frame', style={name='ltnm_icon_slot_table_frame', height=160}, children={
                {type='scroll-pane', style='ltnm_icon_slot_table_scroll_pane', vertical_scroll_policy='always', children={
                  {type='table', style='ltnm_icon_slot_table', column_count=10, save_as='in_transit_table'}
                }},
              }}
            }}
          },
          -- history tab
          {type='tab-and-content', tab={type='tab', caption={'ltnm-gui.history'}, mods={enabled=false}}, content=
            {type='empty-widget'}
          },
          -- alerts tab
          {type='tab-and-content', tab={type='tab', caption={'ltnm-gui.alerts'}, mods={enabled=false}}, content=
            {type='empty-widget'}
          }
        }}
      }}
    }}
  )

  for n,t in pairs{available='green', requested='red', in_transit='blue'} do
    local table = gui_data[n..'_table']
    for i=1,100 do
      table.add{type='sprite-button', style='ltnm_slot_button_'..t, sprite='item/iron-ore', count=1000}
    end
  end


  -- dragging and centering
  gui_data.drag_handle.drag_target = gui_data.window
  gui_data.window.force_auto_center()

  player_table.gui.main = gui_data
end

function self.destroy(player, player_table)
  gui.destroy(player_table.gui.main.window, 'main', player.index)
  player_table.gui.main = nil
end

return self