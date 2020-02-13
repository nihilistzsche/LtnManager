-- -------------------------------------------------------------------------------------------------------------------------------------------------------------
-- CONTROL SCRIPTING

-- debug adapter
pcall(require,'__debugadapter__/debugadapter.lua')

-- dependencies
local event = require('lualib/event')

-- scripts
require('scripts/migrations')

-- globals
ltn_events = {
  on_stops_updated = true,
  on_dispatcher_updated = true,
  on_dispatcher_no_train_found = true,
  on_delivery_pickup_complete = true,
  on_delivery_completed = true,
  on_delivery_failed = true
}

-- -----------------------------------------------------------------------------
-- PROTOTYPING

local function setup_player(player, index)
  global.players[index] = {
    dictionary = {},
    flags = {},
    gui = {}
  }
end

local function setup_ltn_interface()
  if not remote.interfaces['logistic-train-network'] then
    error('Could not establish connection to LTN!')
  end
  for n,_ in pairs(ltn_events) do
    ltn_events[n] = remote.call('logistic-train-network', n)
  end
end

event.on_init(function(e)
  global.players = {}
  for i,p in pairs(game.players) do
    setup_player(p, i)
  end
  setup_ltn_interface()
end)

event.on_load(function(e)
  setup_ltn_interface()
end)

event.on_player_created(function(e)
  setup_player(game.get_player(e.player_index), e.player_index)
end)