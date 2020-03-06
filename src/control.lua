-- -------------------------------------------------------------------------------------------------------------------------------------------------------------
-- CONTROL SCRIPTING

-- dependencies
local event = require('__RaiLuaLib__.lualib.event')
local mod_gui = require('mod-gui')

-- globals
UPDATE_SHORTCUT_EVENT = event.generate_id('update_shortcut_availability')

-- scripts
local data_manager = require('scripts.data-manager')
local main_gui = require('gui.main')
local migrations = require('scripts.migrations')

-- -----------------------------------------------------------------------------
-- INIT

local function setup_player(player, index)
  global.players[index] = {
    dictionary = {},
    flags = {},
    gui = {}
  }
  player.set_shortcut_available('ltnm-toggle-gui', global.flags.shortcut_enabled)
end

event.on_init(function()
  global.flags = {
    shortcut_enabled = false
  }
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

event.register({defines.events.on_lua_shortcut, 'ltnm-toggle-gui'}, function(e)
  if e.input_name or (e.prototype_name == 'ltnm-toggle-gui') then
    local player = game.get_player(e.player_index)
    if not global.flags.shortcut_enabled then return end -- don't follow hotkey if the shortcut is disabled
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
end)

-- enable/disable the shortcut depending on if there's any data
event.register(UPDATE_SHORTCUT_EVENT, function(e)
  global.flags.shortcut_enabled = (global.data.num_stations > 0)
  local enabled = global.flags.shortcut_enabled
  for _,p in pairs(game.players) do
    p.set_shortcut_available('ltnm-toggle-gui', enabled)
  end
end)