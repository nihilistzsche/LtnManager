-- -------------------------------------------------------------------------------------------------------------------------------------------------------------
-- ALERT POPUP GUI
-- HUD to notify you when an alert is triggered

-- dependencies
local event = require('__RaiLuaLib__.lualib.event')
local gui = require('__RaiLuaLib__.lualib.gui')
local mod_gui = require('mod-gui')

-- locals
local string_gsub = string.gsub

-- scripts
local main_gui = require('gui.main')

-- object
local alert_popup_gui = {}

-- -----------------------------------------------------------------------------
-- GUI DATA

gui.handlers:extend{
  alert_popup = {
    button = {
      on_gui_click = function(e)
        local player = game.get_player(e.player_index)
        local player_table = global.players[e.player_index]
        local gui_index = string_gsub(e.element.name, 'ltnm_alert_popup_', '')
        gui_index = tonumber(gui_index)

        if e.button == defines.mouse_button_type.left then
          -- change tab and select correct alert
          main_gui.update(player, player_table, {active_tab='alerts', selected_alert=player_table.gui.alert_popup[gui_index].id})
          -- open in case it's closed
          main_gui.open(player, player_table)
        end
        -- destroy this button
        alert_popup_gui.destroy(player, player_table, gui_index)
      end
    }
  }
}

-- -----------------------------------------------------------------------------
-- FUNCTIONS

function alert_popup_gui.create(player, player_table, data)
  local gui_index = player_table.gui.alert_popup._index
  local gui_data, filters = gui.build(mod_gui.get_frame_flow(player), {
    {type='button', name='ltnm_alert_popup_'..gui_index, style='red_button', style_mods={width=150, height=56}, tooltip={'ltnm-gui.alert-popup-tooltip'},
      mouse_button_filter={'left', 'right'}, handlers='alert_popup.button', save_as='button', children={
        {type='flow', direction='vertical', mods={ignored_by_interaction=true}, children={
          {type='label', style='bold_label', style_mods={font_color={28, 28, 28}}, caption={'ltnm-gui.new-alert'}},
          {type='label', style_mods={font_color={}}, caption={'ltnm-gui.alert-'..data.type}}
        }}
      }
    }
  })

  gui_data.id = data.id
  gui_data.filters = filters
  player_table.gui.alert_popup[gui_index] = gui_data

  -- increment index for next popup
  player_table.gui.alert_popup._index = gui_index + 1
end

function alert_popup_gui.destroy(player, player_table, gui_index)
  local guis = player_table.gui.alert_popup
  local gui_data = guis[gui_index]

  -- update GUI filters
  for group_name,t in pairs(gui_data.filters) do
    for _,name in pairs(event.conditional_event_groups[group_name]) do
      event.update_gui_filters(name, player.index, t, 'remove')
    end
  end

  -- destroy button and remove data
  gui_data.button.destroy()
  guis[gui_index] = nil

  -- disable events if needed
  if table_size(guis) == 1 then
    event.disable_group('gui.alert_popup', player.index)
  end
end

function alert_popup_gui.create_for_all(data)
  local players = global.players
  for _,player in ipairs(game.connected_players) do
    local player_table = players[player.index]
    if player_table.flags.can_open_gui then
      alert_popup_gui.create(player, players[player.index], data)
    end
  end
end

function alert_popup_gui.destroy_all(player, player_table)
  for gui_index,_ in pairs(player_table.gui.alert_popup) do
    if gui_index ~= '_index' then
      alert_popup_gui.destroy(player, player_table, gui_index)
    end
  end
end

-- -----------------------------------------------------------------------------

return alert_popup_gui