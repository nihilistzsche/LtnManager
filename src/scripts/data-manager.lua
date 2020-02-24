-- -------------------------------------------------------------------------------------------------------------------------------------------------------------
-- LTN DATA MANAGER
-- Takes in data from LTN and parses it for use by the GUI
-- This script is the only place to touch LTN data, the rest of the mod uses the data that this script produces.

-- dependencies
local event = require('lualib/event')
local util = require('scripts/util')

-- self object
local self = {}

-- -----------------------------------------------------------------------------
-- HANDLERS

local function on_stops_updated(e)
  -- sort stations by depot
  local depots = {}
  for id,t in pairs(e.logistic_train_stops) do
    if t.isDepot then
      local name = t.entity.backer_name
      local depot = depots[name]
      if depot then
        depot.stations[#depot.stations+1] = id
      else
        depots[name] = {trains={}, stations={id}}
      end
    end
  end
  -- add to global
  global.data = {
    depots = depots,
    stations = e.logistic_train_stops
  }
end

local function on_dispatcher_updated(e)
  local data = global.data
  local depots = data.depots
  local stations = data.stations
  -- assign inventories to each LTN network
  local available = {}
  for id,materials in pairs(e.provided_by_stop) do
    local network_id = stations[id].network_id
    available[network_id] = util.add_materials(materials, available[network_id] or {})
    stations[id].available = materials
  end
  local requested = {}
  for id,materials in pairs(e.requests_by_stop) do
    local network_id = stations[id].network_id
    requested[network_id] = util.add_materials(materials, requested[network_id] or {})
    stations[id].requests = materials
  end
  local in_transit = {}
  for id,t in pairs(e.deliveries) do
    -- in transit inventory
    in_transit[t.network_id] = util.add_materials(t.shipment, in_transit[t.network_id] or {})
    -- assign to depot
    local depot_name = t.train.schedule.records[1].station
    local trains = depots[depot_name].trains
    trains[#trains+1] = id
  end
  -- assign available trains to depot
  for id,t in pairs(e.available_trains) do
    local depot_name = t.train.schedule.records[1].station
    local trains = depots[depot_name].trains
    trains[#trains+1] = id
  end
  -- add to global
  data.inventory = {
    available = available,
    requested = requested,
    in_transit = in_transit,
  }
  data.deliveries = e.deliveries
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