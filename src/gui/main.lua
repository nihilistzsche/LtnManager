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
        {type='tabbed-pane', children={
          -- depots tab
          {type='tab-and-content', tab={type='tab', caption={'ltnm-gui.depots'}}, content=
            {type='empty-widget'}
          },
          -- stations tab
          {type='tab-and-content', tab={type='tab', caption={'ltnm-gui.stations'}}, content=
            {type='empty-widget'}
          },
          -- inventory tab
          {type='tab-and-content', tab={type='tab', caption={'ltnm-gui.inventory'}}, content=
            {type='empty-widget'}
          },
          -- history tab
          {type='tab-and-content', tab={type='tab', caption={'ltnm-gui.history'}}, content=
            {type='empty-widget'}
          },
          -- alerts tab
          {type='tab-and-content', tab={type='tab', caption={'ltnm-gui.alerts'}}, content=
            {type='empty-widget'}
          }
        }}
      }}
    }}
  )

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