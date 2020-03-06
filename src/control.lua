-- -------------------------------------------------------------------------------------------------------------------------------------------------------------
-- CONTROL SCRIPTING

-- dependencies
local event = require('__RaiLuaLib__.lualib.event')
local mod_gui = require('mod-gui')

-- scripts
local data_manager = require('scripts.data-manager')
local main_gui = require('gui.main')
local migrations = require('scripts.migrations')

-- -----------------------------------------------------------------------------
-- UTILITIES

local function create_mod_gui_button(player)
  local button = mod_gui.get_button_flow(player).add{type='sprite-button', name='ltnm_toggle_gui', style=mod_gui.button_style,
    tooltip={'shortcut-name.ltnm-toggle-gui'}, sprite='ltnm_mod_gui_button_icon'}
  button.style.padding = 5
  return button
end

local function setup_player(player, index)
  local data = {
    dictionary = {},
    flags = {},
    gui = {}
  }
  if player.mod_settings['ltnm-show-mod-gui-button'].value then
    data.gui.mod_gui_button = create_mod_gui_button(player)
  end
  global.players[index] = data
end

local function toggle_gui(e)
  local player = game.get_player(e.player_index)
  local player_table = global.players[e.player_index]
  -- toggle GUI
  if player_table.gui.main then
    main_gui.destroy(player, player_table)
  else
    if global.data then
      main_gui.create(player, player_table)
    else
      player.print{'ltnm-message.TEMP-COMEUPWITHANAMESTUPID!'}
    end
  end
  -- set shortcut state
  player.set_shortcut_toggled('ltnm-toggle-gui', player_table.gui.main and true or false)
end

-- -----------------------------------------------------------------------------
-- EVENTS

event.on_init(function()
  global.flags = {}
  global.players = {}
  global.working_data = {history={}, alerts={}}
  for i,p in pairs(game.players) do
    setup_player(p, i)
  end
  data_manager.setup_events()
end, {insert_at_front=true})

event.on_configuration_changed(migrations)

event.on_player_created(function(e)
  setup_player(game.get_player(e.player_index), e.player_index)
end)

event.on_player_removed(function(e)
  global.players[e.player_index] = nil
end)

event.on_runtime_mod_setting_changed(function(e)
  -- add / remove the mod gui button if they changed that setting
  if e.setting == 'ltnm-show-mod-gui-button' then
    local player = game.get_player(e.player_index)
    local player_gui = global.players[e.player_index].gui
    if player_gui.mod_gui_button then
      player_gui.mod_gui_button.destroy()
      player_gui.mod_gui_button = nil
    else
      player_gui.mod_gui_button = create_mod_gui_button(player)
    end
  end
end)

event.register({defines.events.on_lua_shortcut, 'ltnm-toggle-gui'}, function(e)
  if e.input_name or (e.prototype_name == 'ltnm-toggle-gui') then
    toggle_gui(e)
  end
end)

event.on_gui_click(toggle_gui, {gui_filters='ltnm_toggle_gui'})