local ltn_data = {}

local table = require("__flib__.table")

-- -----------------------------------------------------------------------------
-- PROCESSORS

local function iterate_stations(working_data, iterations_per_tick)
  local stations = working_data.stations
  local trains = working_data.trains

  local network_to_stations = working_data.network_to_stations
  local material_locations = working_data.material_locations

  local inventory = working_data.inventory

  local end_index = table.for_n_of(stations, working_data.index, iterations_per_tick, function(station, station_id)
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
    for _, mode in ipairs{"provided", "requested"} do
      local materials = working_data[mode.."_by_stop"][station_id]
      if materials then
        -- add to station
        -- TODO follow up to test performance improvement
        station[mode] = table.shallow_copy(materials)
        -- add to network
        local inv = inventory[mode][network_id]
        if not inv then
          inventory[mode][network_id] = materials
        else
          inv = util.add_materials(materials, inv)
        end
        -- add to lookup
        for name in pairs(materials) do
          local locations = material_locations[name]
          if not locations then
            material_locations[name] = {stations={station_id}, trains={}}
          else
            locations.stations[#locations.stations+1] = station_id
          end
        end
      end
    end

    -- add station trains to trains table
    for _, train in ipairs(station.entity.get_train_stop_trains()) do
      trains[train.id] = {train=train}
    end
  end)

  working_data.index = end_index
  if not end_index then
    working_data.step = 2
  end
end

-- -----------------------------------------------------------------------------
-- HANDLERS

function ltn_data.iterate(e)
  local working_data = global.working_data
  local step = working_data.step

  -- this value will be adjusted per step based on the performance impact
  local iterations_per_tick = settings.global["ltnm-iterations-per-tick"].value

  if step == 1 then
    iterate_stations(working_data, iterations_per_tick)
  elseif step == 2 then
    local breakpoint
  elseif step == 3 then

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
  data.index = 1

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