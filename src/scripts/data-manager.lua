-- -------------------------------------------------------------------------------------------------------------------------------------------------------------
-- LTN DATA MANAGER
-- Takes in data from LTN and parses it for use by the GUI
-- This script is the only place to touch LTN data, the rest of the mod uses the data that this script produces.

-- dependencies
local event = require('lualib/event')

-- self object
local self = {}

-- -----------------------------------------------------------------------------
-- HANDLERS

local function on_stops_updated(e)
  local breakpoint
end

local function on_dispatcher_updated(e)
  local breakpoint
end

local function on_dispatcher_no_train_found(e)
  local breakpoint
end

local function on_delivery_pickup_complete(e)
  local breakpoint
end

local function on_delivery_completed(e)
  local breakpoint
end

local function on_delivery_failed(e)
  local breakpoint
end

-- -----------------------------------------------------------------------------
-- EVENT REGISTRATION

function self.setup_events()
  if not remote.interfaces['logistic-train-network'] then
    error('Could not establish connection to LTN!')
  end
  for id,handler in pairs{
    on_stops_updated = on_stops_updated,
    on_dispatcher_updated = on_dispatcher_updated,
    on_dispatcher_no_train_found = on_dispatcher_no_train_found,
    on_delivery_pickup_complete = on_delivery_pickup_complete,
    on_delivery_completed = on_delivery_completed,
    on_delivery_failed = on_delivery_failed
  }
  do
    event.register(remote.call('logistic-train-network', id), handler)
  end
end

-- -----------------------------------------------------------------------------

return self