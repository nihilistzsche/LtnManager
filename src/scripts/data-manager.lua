-- -------------------------------------------------------------------------------------------------------------------------------------------------------------
-- LTN DATA MANAGER
-- Takes in data from LTN and parses it for use by the GUI
-- This script is the only place to touch LTN data, the rest of the mod uses the data that this script produces.

-- dependencies
local event = require('lualib/event')

-- self object
local self = {}

-- -----------------------------------------------------------------------------
-- STATIONS



-- -----------------------------------------------------------------------------
-- HANDLERS

local function on_stops_updated(e)
  -- organize stations into depots
  local depots = {}
  local stations = {}
  local stations_by_delivery = {}
  for id,t in pairs(e.logistic_train_stops) do
    local entity = t.entity
    local name = entity.backer_name
    if t.isDepot then
      local depot = depots[name]
      if depot then
        depot[#depot+1] = id
      else
        depots[name] = {id}
      end
    end
    stations[id] = t
    local deliveries = t.activeDeliveries
    for i=1,#deliveries do
      stations_by_delivery[deliveries[i]] = id
    end
  end
  global.working = {
    depots = depots,
    stations = stations,
    stations_by_delivery = stations_by_delivery
  }
end

local function on_dispatcher_updated(e)
  local items = {
    available = {},
    in_transit = {},
    outstanding = {}
  }
  local working_data = global.working
  -- sort deliveries
  -- local depots = working_data.depots
  local stations_by_delivery = working_data.stations_by_delivery
  local stations = working_data.stations
  for id,t in pairs(e.deliveries) do
    local station = stations[stations_by_delivery[id]]
    if not station.deliveries then station.deliveries = {} end
    station.deliveries[id] = t
  end
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