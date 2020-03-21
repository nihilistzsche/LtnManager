-- -------------------------------------------------------------------------------------------------------------------------------------------------------------
-- LTN DATA MANAGER
-- Takes in data from LTN and parses it for use by the GUI
-- This script is the only place to touch LTN data, the rest of the mod uses the data that this script produces.

-- dependencies
local event = require('__RaiLuaLib__.lualib.event')
local util = require('scripts.util')

-- locals
local table_insert = table.insert
local table_remove = table.remove
local table_sort = table.sort

local ltn_event_ids = {}

-- object
local data_manager = {}

--[[
  DATA STRUCTURE
  The data is kept in the "data" subtable in global. Working data is kept in "working_data", while the usable data is kept in "data".

  depots
    available_trains (int)
    num_trains (int)
    stations
      (array of station_id)
    trains
      (array of train_id)
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
        name (string)
        count (int)
  inventory
    provided
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
      state
      composition
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
    [array index]
      train_id
      planned_shipment
      actual_shipment
  alerts
    (TBD)
  -- lookup tables - included in output
  network_to_stations
    (dictionary of network_id -> array of train_id)
  material_locations
    [material_name]
      stations
        (array of station_id)
      trains
        (array of train_id)
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
-- PROCESSING FUNCTIONS

local function iterate_stations(data)
  local depots = data.depots
  local stations = data.stations
  local station_ids = data.station_ids
  local num_stations = data.num_stations
  local trains = data.trains
  
  local network_to_stations = data.network_to_stations
  local material_locations = data.material_locations

  local inventory = data.inventory

  local deliveries = data.deliveries
  local available_trains = data.available_trains
  
  local index = data.index
  local num_to_iterate = settings.global['ltnm-stations-per-tick'].value
  local end_index = index + num_to_iterate

  for i=index,end_index do
    local station_id = station_ids[i]
    local station = stations[station_id]
    if not station then error('Station ID mismatch') end
    local network_id = station.network_id
    local station_name = station.entity.backer_name

    -- add station to by-network lookup
    local network_stations = network_to_stations[network_id]
    if network_stations then
      network_stations[#network_stations+1] = station_id
    else
      network_to_stations[network_id] = {station_id}
    end

    -- get status
    local signal = station.lampControl.get_circuit_network(defines.wire_type.red).signals[1]
    station.status = {name=signal.signal.name, count=signal.count}

    -- get station trains
    local station_trains = station.entity.get_train_stop_trains()
    local station_train_ids = {}
    local station_available_trains = 0

    -- iterate trains
    for ti=1,#station_trains do
      local train = station_trains[ti]
      local train_id = train.id
      local train_state = train.state
      local schedule = train.schedule
      if train_state == defines.train_state.wait_station and schedule.records[schedule.current].station == station_name then
        station_available_trains = station_available_trains + 1
      end
      station_train_ids[ti] = train_id

      -- retrieve or construct train table
      if not trains[train_id] then
        local train_data = deliveries[train_id] or available_trains[train_id] or {
          train = train,
          network_id = network_id,
          force = station.entity.force,
          returning_to_depot = true
        }
        train_data.state = train.state
        train_data.depot = schedule.records[1].station
        train_data.composition = util.train.get_composition_string(train)
        train_data.status = {}
        trains[train_id] = train_data
      end
    end

    -- add station and trains to depot
    if station.isDepot then
      local depot = depots[station_name]
      if depot then
        depot.stations[#depot.stations+1] = station_id
      else -- only add trains once, since all depot stations will have the same trains
        depots[station_name] = {available_trains=station_available_trains, num_trains=#station_train_ids, stations={station_id}, trains_temp=station_train_ids}
      end
    end

    -- process station materials
    for _,mode in ipairs{'provided', 'requested'} do
      local materials = data[mode..'_by_stop'][station_id]
      if materials then
        -- add to station
        station[mode] = materials
        -- add to network
        local inv = inventory[mode][network_id]
        if not inv then
          inventory[mode][network_id] = materials
        else
          inv = util.add_materials(materials, inv)
        end
        -- add to lookup
        for name,_ in pairs(materials) do
          local locations = material_locations[name]
          if not locations then
            material_locations[name] = {stations={station_id}, trains={}}
          else
            locations.stations[#locations.stations+1] = station_id
          end
        end
      end
    end

    -- end this step if we are done
    if i == num_stations then
      data.step = 2
      return
    end
  end

  data.index = end_index
end

-- -----------------------------------------------------------------------------
-- HANDLERS

-- called on_tick until data iteration is finished
local function iterate_data()
  local data = global.working_data
  local step = data.step

  if step == 1 then
    iterate_stations(data)
  elseif step == 2 then
    -- process in transit items
    local in_transit = data.inventory.in_transit
    local material_locations = data.material_locations
    for id,t in pairs(data.deliveries) do
      -- add to in transit inventory
      in_transit[t.network_id] = util.add_materials(t.shipment, in_transit[t.network_id] or {})
      -- sort items into locations
      for name,count in pairs(t.shipment) do
        local locations = material_locations[name]
        if not locations then
          material_locations[name] = {stations={}, trains={id}}
        else
          locations.trains[#locations.trains+1] = id
        end
      end
    end
    data.step = 3
  elseif step == 3 then -- sort depot trains
    local depots = data.depots
    local players = global.players
    local trains = data.trains
    for n,depot in pairs(data.depots) do
      local depot_trains = {}
      -- sort by composition - same for all players
      do
        local sort_lookup = {}
        local sort_values = {}
        for _,train_id in ipairs(depot.trains_temp) do
          local train = data.trains[train_id]
          local lookup = sort_lookup[train.composition]
          if lookup then
            lookup[#lookup+1] = train_id
          else
            sort_lookup[train.composition] = {train_id}
          end
          table_insert(sort_values, train.composition)
        end
        table_sort(sort_values)
        local result = {}
        for i,value in ipairs(sort_values) do
          result[i] = table_remove(sort_lookup[value])
        end
        depot_trains.composition = result
      end

      -- sort by status - player-specific based on language
      do
        local results_by_player = {}
        for pi,_ in pairs(game.players) do
          local player_table = players[pi]
          -- only bother if they can actually open the GUI
          if player_table.flags.can_open_gui then
            local sort_lookup = {}
            local sort_values = {}
            local translations = player_table.dictionary.gui.translations
            -- sort trains
            for _,train_id in ipairs(depot.trains_temp) do
              local train = trains[train_id]
              local status = util.train.get_status_string(train, translations)
              -- add status to train data
              train.status[pi] = status
              -- add to sorting tables
              local lookup = sort_lookup[status]
              if lookup then
                lookup[#lookup+1] = train_id
              else
                sort_lookup[status] = {train_id}
              end
              table_insert(sort_values, status)
            end
            table_sort(sort_values)
            local result = {}
            for i,value in ipairs(sort_values) do
              result[i] = table_remove(sort_lookup[value])
            end
            results_by_player[pi] = result
          end
        end
        depot_trains.status = results_by_player
      end
      depot.trains = depot_trains
    end

    -- next step
    data.step = 100
  elseif step == 100 then -- finish up, copy to output
    global.data = {
      depots = data.depots,
      stations = data.stations,
      num_stations = data.num_stations,
      inventory = data.inventory,
      trains = data.trains,
      history = data.history,
      alerts = data.alerts,
      network_to_stations = data.network_to_stations,
      material_locations = data.material_locations
    }
    -- reset events
    event.enable('ltn_on_stops_updated')
    event.enable('ltn_on_dispatcher_updated')
    event.disable('iterate_ltn_data')
  end
end

local function on_stops_updated(e)
  global.working_data.stations = e.logistic_train_stops
end

local function on_dispatcher_updated(e)
  local stations = global.working_data.stations
  if not stations then error('LTN event desync: did not receive stations in time!') end

  -- deregister events for this update cycle
  event.disable('ltn_on_stops_updated')
  event.disable('ltn_on_dispatcher_updated')

  -- set up data tables
  local station_ids = {}
  local station_index = 0
  for station_id,_ in pairs(stations) do
    station_index = station_index + 1
    station_ids[station_index] = station_id
  end

  -- reset data table for iteration
  local data = global.working_data
  data.depots = {}
  data.stations = stations
  data.inventory = {
    provided = {},
    requested = {},
    in_transit = {}
  }
  data.trains = {}
  -- lookup tables
  data.network_to_stations = {}
  data.material_locations = {}
  -- data tables
  data.station_ids = station_ids
  data.num_stations = station_index
  data.provided_by_stop = e.provided_by_stop
  data.requested_by_stop = e.requests_by_stop
  data.deliveries = e.deliveries
  data.available_trains = e.available_trains
  -- iteration data
  data.step = 1
  data.index = 1

  -- enable data iteration handler
  event.enable('iterate_ltn_data')
end

local function on_delivery_pickup_complete(e)
  if not global.data then return end
  local train = global.data.trains[e.train_id]
  if not train then error('Could not find train of ID: '..e.train_id) end
  table.insert(global.working_data.history, 1, {
    type = 'pickup',
    from = train.from,
    to = train.to,
    from_id = train.from_id,
    to_id = train.to_id,
    depot = train.depot,
    actual_shipment = e.actual_shipment,
    planned_shipment = e.planned_shipment,
    runtime = game.tick - train.started
  })
  global.working_data.history[51] = nil -- limit to 50 entries
end

local function on_delivery_completed(e)
  if not global.data then return end
  local train = global.data.trains[e.train_id]
  if not train then error('Could not find train of ID: '..e.train_id) end
  table.insert(global.working_data.history, 1, {
    type = 'delivery',
    from = train.from,
    to = train.to,
    from_id = train.from_id,
    to_id = train.to_id,
    depot = train.depot,
    shipment = e.shipment
  })
  global.working_data.history[51] = nil -- limit to 50 entries
end

local function on_dispatcher_no_train_found(e)
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

function data_manager.setup_events()
  if not remote.interfaces['logistic-train-network'] then
    error('Could not establish connection to LTN!')
  end
  local events = {}
  for id,handler in pairs(ltn_handlers) do
    ltn_event_ids[id] = remote.call('logistic-train-network', id)
    events['ltn_'..id] = {id=ltn_event_ids[id], handler=handler, group='ltn'}
  end
  events.iterate_ltn_data = {id=defines.events.on_tick, handler=iterate_data, options={skip_validation=true}}
  event.register_conditional(events)
end

function data_manager.enable_events()
  event.enable_group('ltn')
end

-- -----------------------------------------------------------------------------

data_manager.ltn_event_ids = ltn_event_ids

return data_manager