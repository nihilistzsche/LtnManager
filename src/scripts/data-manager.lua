-- -------------------------------------------------------------------------------------------------------------------------------------------------------------
-- LTN DATA MANAGER
-- Takes in data from LTN and parses it for use by the GUI
-- This script is the only place to touch LTN data, the rest of the mod uses the data that this script produces.

-- dependencies
local event = require('lualib/event')
local util = require('scripts/util')

-- locals
local ltn_event_ids = {}

-- self object
local self = {}

--[[
  DATA STRUCTURE
  The data is kept in the "data" subtable in global. Working data is kept in "working_data", while the usable data is kept in "data".

  depots
    available_trains (int)
    trains
      (array of train_id)
    stations
      (array of station_id)
  stations
    [station_id]
      -- from LTN
      activeDeliveries,
      entity,
      input,
      output,
      lampControl,
      errorCode,
      isDepot,
      network_id,
      maxTraincars,
      minTraincars,
      trainLimit,
      provideThreshold,
      provideStackThreshold,
      providePriority,
      requestThreshold,
      requestStackThreshold,
      requestPriority,
      lockedSlots,
      noWarnings,
      parkedTrain,
      parkedTrainID,
      parkedTrainFacesStop,

      -- added by us
      trains
        (array of train_id)
      provided
        (dictionary of name -> count)
      requested
        (dictionary of name -> count)
      status
        name
        count
  stations_by_network
    (dictionary of network_id -> array of train_id)
  inventory
    available
      [network_id]
        (dictionary of name -> count)
    requested
      [network_id]
        (dictionary of name -> count)
    in_transit
      [network_id]
        (dictionary of name -> count)
  trains
    [train_id]
      -- common
      force
      train
      network_id
      -- en route
      from
      to
      started
      shipment
        (dictionary or name -> count)
      -- parked at the depot
      capacity
      fluid_capacity
      surface
      -- returning to depot
      returning_to_depot (boolean)
  history
    (TBD)
  alerts
    (TBD)
  -- working data - excluded from output
  provided_by_stop
  requested_by_stop
  deliveries
  available_trains
  station_ids
  num_stations
  -- iteration data - excluded from output
  step (int)
  index (int)
]]

-- -----------------------------------------------------------------------------
-- HANDLERS

-- declare these two here so the iterate_data function can access them
local on_stops_updated, on_dispatcher_updated

-- called on_tick until data iteration is finished
local function iterate_data()
  local data = global.working_data
  local step = data.step
  
  if step == 1 then -- iterate stations
    local depots = data.depots
    local stations = data.stations
    local stations_by_network = data.stations_by_network
    local station_ids = data.station_ids
    local num_stations = data.num_stations
    local trains = data.trains

    local inv_available = data.inventory.available
    local inv_requested = data.inventory.requested
    local inv_in_transit = data.inventory.in_transit

    local provided_by_stop = data.provided_by_stop
    local requested_by_stop = data.requested_by_stop
    local deliveries = data.deliveries
    local available_trains = data.available_trains
    
    local index = data.index
    local num_to_iterate = settings.global['ltnm-stations-per-tick'].value
    local end_index = index + num_to_iterate

    for i=index,end_index do
      local station_id = station_ids[i]
      local station = stations[station_id]
      local network_id = station.network_id
      if not station then error('Station ID mismatch') end

      -- add station to by-network lookup
      local network_stations = stations_by_network[network_id]
      if network_stations then
        network_stations[#network_stations+1] = station_id
      else
        stations_by_network[network_id] = {station_id}
      end

      -- get status
      local signal = station.lampControl.get_circuit_network(defines.wire_type.red).signals[1]
      station.status = {name=signal.signal.name, count=signal.count}

      -- get station trains
      local station_trains = station.entity.get_train_stop_trains()
      local station_train_ids = {}

      -- iterate trains
      for ti=1,#station_trains do
        local train = station_trains[ti]
        local train_id = train.id
        station_train_ids[ti] = train_id

        -- retrieve or construct train table
        if not trains[train_id] then
          trains[train_id] = deliveries[train_id] or available_trains[train_id] or {
            train = train,
            network_id = network_id,
            force = station.entity.force,
            returning_to_depot = true
          }
        end
      end

      -- add station and trains to depot
      if station.isDepot then
        local depot_name = station.entity.backer_name
        local depot = depots[depot_name]
        if depot then
          depot.stations[#depot.stations+1] = station_id
        else
          -- only add trains once, since all stations will have the same trains
          depots[depot_name] = {stations={}, trains=station_train_ids}
        end
      end

      -- process station items
      local provided = provided_by_stop[station_id]
      if provided then
        -- add to station
        station.provided = provided
        -- add to network
        local inventory = inv_available[network_id]
        if not inventory then
          inv_available[network_id] = provided
        else
          inventory = util.add_materials(provided, inventory)
        end
      end
      local requested = requested_by_stop[station_id]
      if requested then
        -- add to station
        station.requested = requested
        -- add to network
        local inventory = inv_requested[network_id]
        if not inventory then
          inv_available[network_id] = requested
        else
          inventory = util.add_materials(requested, inventory)
        end
      end

      -- end this step if we are done
      if i == num_stations then
        data.step = 2
        return
      end
    end

    -- update index
    data.index = end_index
  elseif step == 2 then
    -- process in transit items
    local in_transit = data.inventory.in_transit
    for _,t in pairs(data.deliveries) do
      in_transit[t.network_id] = util.add_materials(t.shipment, in_transit[t.network_id] or {})
    end
    -- next step
    data.step = 100
  elseif step == 100 then -- finish up, copy to output
    global.data = {
      depots = data.depots,
      stations = data.stations,
      stations_by_network = data.stations_by_network,
      inventory = data.inventory,
      trains = data.trains,
      history = data.history,
      alerts = data.alerts
    }
    global.working_data = nil
    -- reset events
    event.deregister_conditional(iterate_data, 'iterate_ltn_data')
    event.register(ltn_event_ids.on_stops_updated, on_stops_updated, {name='ltn_on_stops_updated'})
    event.register(ltn_event_ids.on_dispatcher_updated, on_dispatcher_updated, {name='ltn_on_dispatcher_updated'})
  end
end

function on_stops_updated(e)
  global.working_data = {stations=e.logistic_train_stops}
end

function on_dispatcher_updated(e)
  local stations = global.working_data.stations
  if not stations then error('LTN event desync: did not receive stations in time!') end

  -- deregister events for this update cycle
  event.deregister_conditional(on_stops_updated, 'ltn_on_stops_updated')
  event.deregister_conditional(on_dispatcher_updated, 'ltn_on_dispatcher_updated')

  -- set up data tables
  local station_ids = {}
  local station_index = 0
  for station_id,_ in pairs(stations) do
    station_index = station_index + 1
    station_ids[station_index] = station_id
  end

  -- set up data table for iteration
  global.working_data = {
    -- output tables
    depots = {},
    stations = stations,
    stations_by_network = {},
    inventory = {
      available = {},
      requested = {},
      in_transit = {}
    },
    trains = {},
    history = {},
    alerts = {},
    -- data tables
    station_ids = station_ids,
    num_stations = station_index,
    provided_by_stop = e.provided_by_stop,
    requested_by_stop = e.requests_by_stop,
    deliveries = e.deliveries,
    available_trains = e.available_trains,
    -- iteration data
    step = 1,
    index = 1
  }

  -- register data iteration handler
  event.on_tick(iterate_data, {name='iterate_ltn_data', skip_validation=true})
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

local ltn_handlers = {
  on_stops_updated = on_stops_updated,
  on_dispatcher_updated = on_dispatcher_updated,
  on_dispatcher_no_train_found = on_dispatcher_no_train_found,
  on_delivery_pickup_complete = on_delivery_pickup_complete,
  on_delivery_completed = on_delivery_completed,
  on_delivery_failed = on_delivery_failed
}

function self.setup_events()
  if not remote.interfaces['logistic-train-network'] then
    error('Could not establish connection to LTN!')
  end
  for id,handler in pairs(ltn_handlers) do
    ltn_event_ids[id] = remote.call('logistic-train-network', id)
    event.register(ltn_event_ids[id], handler, {name=id})
  end
end

-- re-register the events in on_load
event.on_load(function()
  event.load_conditional_handlers(ltn_handlers)
end)

-- -----------------------------------------------------------------------------

return self