local ltn_data = {}

local table = require("__flib__.table")

-- -----------------------------------------------------------------------------
-- PROCESSORS

local function iterate_stations(working_data, iterations_per_tick)
  local depots = working_data.depots
  local station_ids = working_data.station_ids
  local trains = working_data.trains

  local network_to_stations = working_data.network_to_stations
  local material_locations = working_data.material_locations

  local inventory = working_data.inventory

  return table.for_n_of(working_data.stations, working_data.key, iterations_per_tick, function(station, station_id)
    -- check station validity
    if not station.entity.valid or not station.input.valid or not station.output.valid then return end

    local network_id = station.network_id
    local station_name = station.entity.backer_name

    -- add station to by-network lookup
    local network_stations = network_to_stations[network_id]
    if network_stations then
      network_stations[#network_stations+1] = station_id -- TODO check performance
    else
      network_to_stations[network_id] = {station_id}
    end

    -- get status
    local signal = station.lamp_control.get_control_behavior().get_signal(1)
    station.status = {name=signal.signal.name, count=signal.count}

    -- process station materials
    -- TODO consider other methods (might be slow with large amounts of materials in a station)
    -- TODO follow up on performance improvements?
    for _, mode in ipairs{"provided", "requested"} do
      local materials = working_data[mode.."_by_stop"][station_id]
      if materials then
        local materials_copy = {}
        for name, count in pairs(materials) do
          -- add to lookup
          local locations = material_locations[name]
          if not locations then
            material_locations[name] = {stations={station_id}, trains={}}
          else
            locations.stations[#locations.stations+1] = station_id
          end
          -- copy
          materials_copy[name] = count
        end
        -- add to station
        station[mode] = materials_copy
        -- add to network
        local inv = inventory[mode][network_id]
        if not inv then
          inventory[mode][network_id] = materials
        else
          inv = util.add_materials(materials, inv)
        end
      end
    end

    -- add station trains to trains table
    local station_trains = station.entity.get_train_stop_trains()
    for _, train in ipairs(station_trains) do
      trains[train.id] = {train=train}
    end

    -- add station to depot
    if station.is_depot then
      local depot = depots[station_name]
      if depot then
        depot.stations[#depot.stations+1] = station_id
      else
        depots[station_name] = {available_trains={}, num_trains=#station_trains, stations={station_id}, trains={}}
      end
    end

    -- sorting data
    station_ids[#station_ids+1] = station_id
    working_data.num_stations = working_data.num_stations + 1
  end)
end

local function iterate_trains(working_data, iterations_per_tick)
  local depots = working_data.depots
  local trains = working_data.trains

  local deliveries = working_data.deliveries
  local available_trains = working_data.available_trains

  return table.for_n_of(trains, working_data.key, iterations_per_tick / 2, function(train_data, train_id)
    local train = train_data.train
    local train_state = train.state
    local schedule = train.schedule
    local depot = schedule.records[1].station
    local depot_data = depots[depot]
    if train_state == defines.train_state.wait_station and schedule.records[schedule.current].station == depot then
      depot_data.available_trains[#depot_data.available_trains+1] = train_id
      depot_data.trains[#depot_data.trains+1] = train_id
    end

    -- construct train data
    train_data.state = train_state
    train_data.depot = depot
    train_data.composition = util.train.get_composition_string(train)
    train_data.main_locomotive = util.train.get_main_locomotive(train)
    train_data.status = {}
    trains[train_id] = train_data
    for key, value in pairs(
      deliveries[train_id]
      or available_trains[train_id]
      or {
      train = train,
      network_id = depot_data.network_id,
      force = depot_data.entity.force,
      returning_to_depot = true
      }
    ) do
      train_data[key] = value
    end
  end)
end

-- -----------------------------------------------------------------------------
-- HANDLERS

function ltn_data.iterate(e)
  local working_data = global.working_data
  local step = working_data.step

  -- this value will be adjusted per step based on the performance impact
  local iterations_per_tick = settings.global["ltnm-iterations-per-tick"].value

  local processors = {
    iterate_stations,
    iterate_trains
  }

  if processors[step] then
    local end_key = processors[step](working_data, iterations_per_tick)
    working_data.key = end_key
    if not end_key then
      working_data.step = step + 1
    end
  else
    global.flags.iterating_ltn_data = false
  end
end

function ltn_data.on_stops_updated(e)
  if global.flags.iterating_ltn_data then return end
  global.working_data.stations = e.logistic_train_stops
end

function ltn_data.on_dispatcher_updated(e)
  if global.flags.iterating_ltn_data or global.flags.updating_guis then return end
  local stations = global.working_data.stations
  if not stations then
    log("LTN event desync: did not receive stations in time! Skipping iteration.")
    global.working_data.stations = nil
    return
  end

  -- set up data tables
  local station_ids = {}
  local station_index = 0
  for station_id in pairs(stations) do
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
  data.station_ids = {}
  data.num_stations = 0
  data.provided_by_stop = e.provided_by_stop
  data.requested_by_stop = e.requests_by_stop
  data.deliveries = e.deliveries
  data.available_trains = e.available_trains
  -- iteration data
  data.step = 1
  data.key = 1

  -- enable data iteration handler
  global.flags.iterating_ltn_data = true
end

-- -----------------------------------------------------------------------------
-- MODULE

ltn_data.event_ids = {}

function ltn_data.init()
  global.data = nil
  global.working_data = {history={}, alerts={}}
  global.flags.iterating_ltn_data = false
  global.flags.updating_guis = false
end

return ltn_data