-- -------------------------------------------------------------------------------------------------------------------------------------------------------------
-- CONTROL SCRIPTING

-- debug adapter
pcall(require,'__debugadapter__/debugadapter.lua')

-- dependencies
local event = require('lualib/event')
local mod_gui = require('mod-gui')

-- scripts
local data_manager = require('scripts/data-manager')
local main_gui = require('gui/main')
local migrations = require('scripts/migrations')

-- -----------------------------------------------------------------------------
-- PROTOTYPING

local function setup_player(player, index)
  global.players[index] = {
    dictionary = {},
    flags = {},
    gui = {}
  }
  mod_gui.get_button_flow(player).add{type='button', name='ltnm_button', style=mod_gui.button_style, caption='LTNM'}
end

event.on_init(function()
  global.data = {}
  global.flags = {

  }
  global.players = {}
  for i,p in pairs(game.players) do
    setup_player(p, i)
  end
  data_manager.setup_events()
end)

event.on_load(function()
  data_manager.setup_events()
end)

event.on_player_created(function(e)
  setup_player(game.get_player(e.player_index), e.player_index)
end)

event.on_configuration_changed(migrations)

event.on_gui_click(function(e)
  local player = game.get_player(e.player_index)
  local player_table = global.players[e.player_index]
  if player_table.gui.main then
    main_gui.destroy(player, player_table)
  else
    main_gui.create(player, player_table)
  end
end, {gui_filters='ltnm_button'})