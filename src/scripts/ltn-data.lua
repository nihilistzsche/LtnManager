local ltn_data = {}

local table = require("__flib__.table")

local constants = require("constants")

local alert_popup_gui = require("scripts.gui.alert-popup")

-- -----------------------------------------------------------------------------
-- HELPER FUNCTIONS

local function add_alert(e, alert_type, shipment)
  -- save train data so it will persist after the delivery is through
  local trains = global.data.trains
  local train = trains[e.train_id] or trains[global.data.invalidated_trains[e.train_id]]
  if not train then error("Could not find train of ID: "..e.train_id) end

  -- add common data
  local alert_data = {
    time = game.tick,
    type = alert_type,
    train = {
      depot = train.depot,
      from = train.from,
      from_id = train.from_id,
      id = e.train_id,
      network_id = train.network_id,
      pickup_done = train.pickupDone or false,
      to = train.to,
      to_id = train.to_id,
      route = train.from.." -> "..train.to
    }
  }

  -- add unique data
  if alert_type == "incorrect_pickup" then
    alert_data.actual_shipment = util.add_materials(e.actual_shipment)
    alert_data.planned_shipment = e.planned_shipment
  elseif alert_type == "incomplete_delivery" then
    alert_data.leftovers = e.remaining_load
    alert_data.shipment = e.shipment
  else
    alert_data.shipment = shipment
  end

  -- save to data table
  local alerts = global.data.alerts
  table.insert(alerts, 1, alert_data)
  alerts[31] = nil -- limit to 30 entries

  -- set popup flag
  global.working_data.alert_popup = alert_type
end

-- -----------------------------------------------------------------------------
-- PROCESSORS

local function iterate_stations(working_data, iterations_per_tick)
  local depots = working_data.depots
  local sorted_stations = working_data.sorted_stations
  local trains = working_data.trains

  local network_to_stations = working_data.network_to_stations
  local material_locations = working_data.material_locations

  local inventory = working_data.inventory

  return table.for_n_of(working_data.stations, working_data.key, iterations_per_tick, function(station_data, station_id)
    -- check station validity
    if not station_data.entity.valid or not station_data.input.valid or not station_data.output.valid then return end

    local network_id = station_data.network_id
    local station_name = station_data.entity.backer_name

    -- add name to data
    station_data.name = station_name

    -- add station to by-network lookup
    local network_stations = network_to_stations[network_id]
    if network_stations then
      network_stations[#network_stations+1] = station_id
    else
      network_to_stations[network_id] = {station_id}
    end

    -- get status
    local signal = station_data.lamp_control.get_control_behavior().get_signal(1)
    station_data.status = {name=signal.signal.name, count=signal.count, sort_key=signal.signal.name..signal.count}

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
        station_data[mode] = materials_copy
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
    local station_trains = station_data.entity.get_train_stop_trains()
    for _, train in ipairs(station_trains) do
      trains[train.id] = {train=train}
    end

    -- add station to depot
    if station_data.is_depot then
      local depot = depots[station_name]
      if depot then
        depot.stations[#depot.stations+1] = station_id
      else
        depots[station_name] = {
          available_trains = {},
          force = station_data.entity.force,
          network_id = network_id,
          num_trains = #station_trains,
          stations = {station_id},
          train_ids = {},
          sorted_trains = {
            composition = {},
            status = {}
          }
        }
      end
    end

    -- sorting data
    sorted_stations.name[#sorted_stations.name+1] = station_id
    sorted_stations.status[#sorted_stations.status+1] = station_id
    working_data.num_stations = working_data.num_stations + 1
  end)
end

local function iterate_trains(working_data, iterations_per_tick)
  local depots = working_data.depots
  local trains = working_data.trains

  local deliveries = working_data.deliveries
  local available_trains = working_data.available_trains

  return table.for_n_of(trains, working_data.key, math.ceil(iterations_per_tick / 2), function(train_data, train_id)
    local train = train_data.train
    local train_state = train.state
    local schedule = train.schedule
    local depot = schedule.records[1].station
    local depot_data = depots[depot]

    -- not every train will be LTN-controlled
    if not depot_data then return nil, true end

    -- add to depot trains lists
    local train_ids = depot_data.train_ids
    train_ids[#train_ids+1] = train_id
    local sorted_trains = depot_data.sorted_trains
    sorted_trains.composition[#sorted_trains.composition+1] = train_id
    if train_state == defines.train_state.wait_station and schedule.records[schedule.current].station == depot then
      depot_data.available_trains[#depot_data.available_trains+1] = train_id
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
        force = depot_data.force,
        returning_to_depot = true
      }
    ) do
      train_data[key] = value
    end
  end)
end

local function iterate_in_transit(working_data, iterations_per_tick)
  local in_transit = working_data.inventory.in_transit
  local material_locations = working_data.material_locations

  return table.for_n_of(working_data.deliveries, working_data.key, iterations_per_tick, function(delivery_data, delivery_id)
    -- add to in transit inventory
    in_transit[delivery_data.network_id] = util.add_materials(delivery_data.shipment, in_transit[delivery_data.network_id] or {})
    -- sort materials into locations
    for name in pairs(delivery_data.shipment) do
      local locations = material_locations[name]
      if not locations then
        material_locations[name] = {stations={}, trains={delivery_id}}
      else
        locations.trains[#locations.trains+1] = delivery_id
      end
    end
  end)
end

local function generate_train_status_strings(working_data, iterations_per_tick)
  local players = global.players
  local trains  = working_data.trains

  return table.for_n_of({}, working_data.key, iterations_per_tick,
    function(data, key)
      local train = trains[key.train]
      train.status[key.player] = util.train.get_status_string(train, data.translations)
    end,
    function(_, key)
      key = key or {player=next(players)}
      local player = key.player
      local train = key.train

      -- find new keys
      local next_train = next(trains, key.train)
      if next_train then
        train = next_train
        player = key.player
      else
        train = next(trains)
        local next_player = next(players, player)
        if next_player then
          player = next_player
        else
          -- we have finished, so return `nil` to cease iteration
          return nil, nil
        end
      end

      -- return tables
      return
        {player=player, train=train},
        {translations=players[player].translations.gui, train=trains[train]}
    end
  )
end

local function sort_depot_trains_by_status(working_data)
  local players = global.players
  local depots = working_data.depots
  local trains = working_data.trains

  return table.for_n_of({}, working_data.key, 1,
    function(depot_data, key)
      local train_ids = table.array_copy(depot_data.train_ids)
      local player_index = key.player

      table.sort(train_ids, function(id_1, id_2)
        return trains[id_1].status[player_index].string < trains[id_2].status[player_index].string
      end)

      depot_data.sorted_trains.status[player_index] = train_ids
    end,
    function(_, key)
      key = key or {player=next(players)}
      local player = key.player
      local depot = key.depot

      -- find new keys
      local next_depot = next(depots, key.depot)
      if next_depot then
        depot = next_depot
        player = key.player
      else
        depot = next(depots)
        local next_player = next(players, player)
        if next_player then
          player = next_player
        else
          -- we have finished, so return `nil` to cease iteration
          return nil, nil
        end
      end

      -- return tables
      return
        {player=player, depot=depot},
        depots[depot]
    end
  )
end

local function sort_depot_trains_by_composition(working_data)
  local trains = working_data.trains
  return table.for_n_of(working_data.depots, working_data.key, 1, function(depot)
    table.sort(depot.sorted_trains.composition, function(id_1, id_2)
      return trains[id_1].composition < trains[id_2].composition
    end)
  end)
end

local function sort_stations_by_name(working_data, iterations_per_tick)
  local stations = working_data.stations
  return table.partial_sort(working_data.sorted_stations.name, working_data.key, math.ceil(iterations_per_tick / 2), function(id_1, id_2)
    return stations[id_1].name < stations[id_2].name
  end)
end

local function sort_stations_by_status(working_data, iterations_per_tick)
  local stations = working_data.stations
  return table.partial_sort(
    working_data.sorted_stations.status,
    working_data.key,
    math.ceil(iterations_per_tick / 2),
    function(id_1, id_2)
      return stations[id_1].status.sort_key < stations[id_2].status.sort_key
    end
  )
end

local function remove_deleted_alerts_and_history(working_data)
  local flags = global.flags
  -- history
  if flags.deleted_history then
    working_data.history = {}
    flags.deleted_history = false
  end
  -- alerts
  if flags.deleted_all_alerts then
    working_data.alerts = {}
    flags.deleted_all_alerts = false
  else
    for id in pairs(flags.deleted_alerts) do
      table.remove(working_data.alerts, id)
    end
    flags.deleted_alerts = {}
  end
end

local function prepare_history_alerts_sort(working_data)
  local history = working_data.history
  local history_length = #history
  local sorted_history = working_data.sorted_history
  -- add IDs to arrays
  for _, array in pairs(sorted_history) do
    for i = 1, history_length do
      array[i] = i
    end
  end

  local alerts = working_data.alerts
  local alerts_length = #alerts
  local sorted_alerts = working_data.sorted_alerts
  -- add IDs to array
  for _, array in pairs(sorted_alerts) do
    for i = 1, alerts_length do
      array[i] = i
    end
  end
end

local function sort_history(working_data, iterations_per_tick)
  local history = working_data.history
  local sorted_history = working_data.sorted_history

  local key = working_data.key or {sort=next(constants.history_sorts)}
  local sort = key.sort

  local next_index = table.partial_sort(
    sorted_history[key.sort],
    key.index,
    math.ceil(iterations_per_tick / 2),
    function(id_1, id_2)
      return history[id_1][sort] < history[id_2][sort]
    end
  )

  key.index = next_index
  if not next_index then
    local next_sort = next(constants.history_sorts, sort)
    if next_sort then
      key.sort = next_sort
    else
      key = nil
    end
  end

  return key
end

local function sort_alerts(working_data, iterations_per_tick)
  local alerts = working_data.alerts
  local sorted_alerts = working_data.sorted_alerts

  local key = working_data.key or {sort=next(constants.alerts_sorts)}
  local sort = key.sort

  local next_index = table.partial_sort(
    sorted_alerts[key.sort],
    key.index,
    math.ceil(iterations_per_tick / 2),
    function(id_1, id_2)
      local alert_1 = alerts[id_1]
      local alert_2 = alerts[id_2]
      return (alert_1[sort] or alert_1.train[sort]) < (alerts[id_2][sort] or alert_2.train[sort])
    end
  )

  key.index = next_index
  if not next_index then
    local next_sort = next(constants.alerts_sorts, sort)
    if next_sort then
      key.sort = next_sort
    else
      key = nil
    end
  end

  return key
end

-- -----------------------------------------------------------------------------
-- HANDLERS

function ltn_data.iterate()
  local working_data = global.working_data
  local step = working_data.step

  -- this value will be adjusted per step based on the performance impact
  local iterations_per_tick = settings.global["ltnm-iterations-per-tick"].value

  local processors = {
    iterate_stations,
    iterate_trains,
    iterate_in_transit,
    generate_train_status_strings,
    sort_depot_trains_by_status,
    sort_depot_trains_by_composition,
    sort_stations_by_name,
    sort_stations_by_status,
    remove_deleted_alerts_and_history,
    prepare_history_alerts_sort,
    sort_history,
    sort_alerts
  }

  if processors[step] then
    local end_key = processors[step](working_data, iterations_per_tick)
    working_data.key = end_key
    if not end_key then
      working_data.step = step + 1
    end
  else
    local prev_data = global.data
    -- output data
    global.data = {
      -- bulk data
      depots = working_data.depots,
      stations = working_data.stations,
      inventory = working_data.inventory,
      trains = working_data.trains,
      history = working_data.history,
      alerts = working_data.alerts,
      -- lookup tables
      network_to_stations = working_data.network_to_stations,
      material_locations = working_data.material_locations,
      -- sorting tables
      sorted_stations = working_data.sorted_stations,
      sorted_history = working_data.sorted_history,
      sorted_alerts = working_data.sorted_alerts,
      -- other
      num_stations = working_data.num_stations,
      invalidated_trains = {}
    }

    if working_data.alert_popup then
      alert_popup_gui.create_for_all(working_data.alert_popup)
    end

    -- reset working data
    global.working_data = {
      history = global.working_data.history,
      alerts = global.working_data.alerts
    }

    -- start updating GUIs
    global.flags.iterating_ltn_data = false
    global.flags.updating_guis = true
    global.next_update_index = next(global.players)
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
  data.num_stations = 0
  data.provided_by_stop = e.provided_by_stop
  data.requested_by_stop = e.requests_by_stop
  data.deliveries = e.deliveries
  data.available_trains = e.available_trains
  -- sorting tables
  data.sorted_stations = {name={}, status={}}
  data.sorted_history = {
    depot = {},
    route = {},
    runtime = {},
    finished = {}
  }
  data.sorted_alerts = {
    network_id = {},
    route = {},
    time = {},
    type = {}
  }
  -- iteration data
  data.step = 1
  data.key = 1

  -- enable data iteration handler
  global.flags.iterating_ltn_data = true
end

function ltn_data.on_delivery_completed(e)
  local data = global.data
  if not data then return end
  local trains = data.trains
  local train = trains[e.train_id] or trains[data.invalidated_trains[e.train_id]]
  if not train then error("Could not find train of ID ["..e.train_id.."]") end

  if not train.started then
    log("Shipment of ID ["..e.train_id.."] is missing some data. Skipping!")
    return
  end

  -- add to delivery history
  table.insert(global.working_data.history, 1, {
    type = "delivery",
    from = train.from,
    to = train.to,
    from_id = train.from_id,
    to_id = train.to_id,
    network_id = train.network_id,
    depot = train.depot,
    shipment = e.shipment,
    runtime = game.tick - train.started,
    finished = game.tick,
    route = train.from.." -> "..train.to
  })
  global.working_data.history[51] = nil -- limit to 50 entries
end

function ltn_data.on_delivery_failed(e)
  if not global.data then return end

  local trains = global.data.trains
  local train = trains[e.train_id] or trains[global.data.invalidated_trains[e.train_id]]

  if train then
    local alert_type
    if train.train.valid then
      alert_type = "delivery_timed_out"
    else
      alert_type = "train_invalidated"
    end

    add_alert(e, alert_type, train.shipment)
  end
end

function ltn_data.on_train_created(e)
  if not global.data then return end
  local trains = global.data.trains
  local invalidated_trains = global.data.invalidated_trains
  local new_train = e.train
  local new_id = new_train.id
  -- migrate train IDs and information
  for i=1,2 do
    local old_id = e["old_train_id_"..i]
    if old_id then
      local train_data = trains[old_id] or trains[invalidated_trains[old_id]]
      if train_data then
        -- add a mapping for alerts
        invalidated_trains[new_id] = invalidated_trains[old_id] or old_id
        invalidated_trains[old_id] = nil
        -- replace train and main_locomotive, the actual IDs and such will be updated on the next LTN update cycle
        train_data.train = new_train
        train_data.main_locomotive = util.train.get_main_locomotive(new_train)
      end
    end
  end
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