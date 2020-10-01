local ltn_data = {}

local event = require("__flib__.event")
local queue = require("lib.queue")
local table = require("__flib__.table")
local util = require("scripts.util")

local constants = require("constants")

-- -----------------------------------------------------------------------------
-- HELPER FUNCTIONS

local function add_alert(e)
  -- save train data so it will persist after the delivery is through
  local train_id = e.train_id or e.train.id
  local alert_type = ltn_data.alert_types[e.name]

  -- add common data
  local alert_data = {
    time = game.tick,
    type = alert_type,
    train_id = train_id,
    use_working_data = global.flags.iterating_ltn_data or not global.data
  }

  -- add unique data
  if alert_type == "provider_missing_cargo" then
    alert_data.actual_shipment = e.actual_shipment
    alert_data.planned_shipment = e.planned_shipment
  elseif alert_type == "provider_unscheduled_cargo" or alert_type == "requester_unscheduled_cargo" then
    alert_data.planned_shipment = e.planned_shipment
    alert_data.unscheduled_load = e.unscheduled_load
  elseif alert_type == "requester_remaining_cargo" then
    alert_data.remaining_load = e.remaining_load
  elseif alert_type == "delivery_failed" then
    alert_data.planned_shipment = e.planned_shipment
  end

  -- add to temporary table
  global.active_data.alerts_to_add[#global.active_data.alerts_to_add+1] = alert_data
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
    station_data.status = {name = signal.signal.name, count = signal.count, sort_key = signal.signal.name..signal.count}

    -- process station materials
    for _, mode in ipairs{"provided", "requested"} do
      local materials = working_data[mode.."_by_stop"][station_id]
      if materials then
        local materials_copy = {}
        for name, count in pairs(materials) do
          -- add to lookup
          local locations = material_locations[name]
          if not locations then
            material_locations[name] = {stations = {station_id}, trains = {}}
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
      trains[train.id] = {train = train}
    end

    -- add station to depot
    if station_data.is_depot then
      local depot = depots[station_name]
      if depot then
        depot.stations[#depot.stations+1] = station_id
        depot.surfaces[station_data.entity.surface.index] = true
      else
        depots[station_name] = {
          available_trains = {},
          force = station_data.entity.force,
          network_id = network_id,
          num_trains = #station_trains,
          stations = {station_id},
          surfaces = {[station_data.entity.surface.index] = true},
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

    -- checks
    if not train.valid then
      if working_data.aborted_trains[train_id] then
        -- migrations didn't work, so delete this train and try again next cycle
        return nil, true
      else
        -- abort and try again next tick to allow for migrations
        working_data.aborted_trains[train_id] = true
        return nil, nil, true
      end
    end

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

  return table.for_n_of(
    working_data.deliveries,
    working_data.key,
    iterations_per_tick,
    function(delivery_data, delivery_id)
      -- add to in transit inventory
      in_transit[delivery_data.network_id] = util.add_materials(
        delivery_data.shipment,
        in_transit[delivery_data.network_id] or {}
      )
      -- sort materials into locations
      for name in pairs(delivery_data.shipment) do
        local locations = material_locations[name]
        if not locations then
          material_locations[name] = {stations = {}, trains = {delivery_id}}
        else
          locations.trains[#locations.trains+1] = delivery_id
        end
      end
    end
  )
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
      key = key or {}
      local player = key.player
      local train = key.train

      -- find new keys
      local next_train = next(trains, key.train)
      if next_train and player then
        train = next_train
        player = key.player
      else
        train = next(trains)
        local next_player = next(players, player)
        while next_player do
          if players[next_player].flags.translations_finished then
            break
          end
          next_player = next(players, next_player)
        end
        if next_player and train then
          player = next_player
        else
          -- we have finished, so return `nil` to cease iteration
          return nil, nil
        end
      end

      -- return tables
      return
        {player = player, train = train},
        {translations = players[player].translations.gui, train = trains[train]}
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
      key = key or {}
      local player = key.player
      local depot = key.depot

      -- find new keys
      local next_depot = next(depots, key.depot)
      if next_depot and player then
        depot = next_depot
        player = key.player
      else
        depot = next(depots)
        local next_player = next(players, player)
        while next_player do
          if players[next_player].flags.translations_finished then
            break
          end
          next_player = next(players, next_player)
        end
        if next_player and depot then
          player = next_player
        else
          -- we have finished, so return `nil` to cease iteration
          return nil, nil
        end
      end

      -- return tables
      return
        {player = player, depot = depot},
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
  return table.partial_sort(
    working_data.sorted_stations.name,
    working_data.key,
    math.ceil(iterations_per_tick / 2),
    function(id_1, id_2)
      return stations[id_1].name < stations[id_2].name
    end
  )
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

local function update_history(working_data)
  local active_data = global.active_data
  local active_history = active_data.history
  -- delete if necessary
  if global.flags.deleted_history then
    active_data.history = queue.new()
    active_history = active_data.history
    global.flags.deleted_history = false
    active_data.added_history = {}
  end

  -- add new entries
  for _, entry in pairs(active_data.history_to_add) do
    local trains = entry.use_working_data and working_data.trains or global.data.trains
    local train = trains[entry.train_id] or trains[global.active_data.invalidated_trains[entry.train_id]]
    -- if the train is returning to its depot or doesn't exist
    if not train or not train.to then
      -- check for `data`
      if entry.use_working_data and not global.data then goto continue end
      -- try other table
      trains = entry.use_working_data and global.data.trains or working_data.trains
      train = trains[entry.train_id] or trains[global.active_data.invalidated_trains[entry.train_id]]
      -- there's nothing we can do, so skip this one
      if not train or not train.to then goto continue end
    end
    -- sometimes LTN will forget to include `started`, in which case, skip this one
    if train.started then
      -- add remaining info
      entry.from = train.from
      entry.to = train.to
      entry.from_id = train.from_id
      entry.to_id = train.to_id
      entry.network_id = train.network_id
      entry.depot = train.depot
      entry.route = train.from.." -> "..train.to
      entry.runtime = entry.finished - train.started
      -- add to history
      queue.push_right(active_history, entry)
      -- limit to 50 entries
      if queue.length(active_history) > 50 then
        queue.pop_left(active_history)
      end
    end
    ::continue::
  end
  -- clear add table
  active_data.history_to_add = {}
end

local function prepare_history_sort(working_data)
  local active_data = global.active_data
  local active_history = active_data.history

  -- copy to working data
  working_data.history = table.shallow_copy(active_history)

  -- populate sorting tables
  local sorted_history = working_data.sorted_history
  -- add IDs to array
  local history_ids = {}
  for i in queue.iter_left(active_history) do
    history_ids[#history_ids+1] = i
  end
  -- copy to each table
  for key in pairs(sorted_history) do
    sorted_history[key] = table.array_copy(history_ids)
  end
end

local function sort_history(working_data, iterations_per_tick)
  local history = working_data.history
  local sorted_history = working_data.sorted_history

  local key = working_data.key or {sort = next(sorted_history)}
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
    local next_sort = next(sorted_history, sort)
    if next_sort then
      key.sort = next_sort
    else
      key = nil
    end
  end

  return key
end

local function update_alerts(working_data)
  local active_data = global.active_data
  local active_alerts = active_data.alerts
  local flags = global.flags

  -- delete alerts if necessary
  if flags.deleted_all_alerts then
    active_data.alerts = queue.new()
    active_alerts = active_data.alerts
  else
    queue.pop_multi(active_alerts, active_data.alerts_to_delete)
  end
  active_data.alerts_to_delete = {}

  -- add new alerts
  for _, alert_data in pairs(active_data.alerts_to_add) do
    local trains = alert_data.use_working_data and working_data.trains or global.data.trains
    local train = trains[alert_data.train_id] or trains[global.active_data.invalidated_trains[alert_data.train_id]]
    -- if the train is returning to its depot or doesn't exist
    if not train or not train.to then
      -- check for `data`
      if alert_data.use_working_data and not global.data then goto continue end
      -- try other table
      trains = alert_data.use_working_data and global.data.trains or working_data.trains
      train = trains[alert_data.train_id] or trains[global.active_data.invalidated_trains[alert_data.train_id]]
      -- there's nothing we can do, so skip this one
      if not train or not train.to then goto continue end
    end
    alert_data.train = {
      depot = train.depot,
      from = train.from,
      from_id = train.from_id,
      id = alert_data.train_id,
      network_id = train.network_id,
      pickup_done = train.pickupDone or false,
      to = train.to,
      to_id = train.to_id,
      route = train.from.." -> "..train.to
    }
    -- save to alerts table
    queue.push_right(active_alerts, alert_data)
    -- limit to 30 entries
    if queue.length(active_alerts) > 30 then
      queue.pop_left(active_alerts)
    end
    ::continue::
  end
  active_data.alerts_to_add = {}
end

local function prepare_alerts_sort(working_data)
  local active_alerts = global.active_data.alerts
  -- copy to working data
  working_data.alerts = table.shallow_copy(active_alerts)

  -- populate sorting tables
  local sorted_alerts = working_data.sorted_alerts
  -- add IDs to array
  local alert_ids = {}
  for i in queue.iter_left(active_alerts) do
    alert_ids[#alert_ids+1] = i
  end
  -- copy to each table
  for key in pairs(sorted_alerts) do
    sorted_alerts[key] = table.array_copy(alert_ids)
  end
end

local function sort_alerts(working_data, iterations_per_tick)
  local alerts = working_data.alerts
  local sorted_alerts = working_data.sorted_alerts

  local key = working_data.key or {sort = next(sorted_alerts)}
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
    local next_sort = next(sorted_alerts, sort)
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
    update_history,
    prepare_history_sort,
    sort_history,
    update_alerts,
    prepare_alerts_sort,
    sort_alerts
  }

  if processors[step] then
    local end_key, is_for_n_of, for_n_of_finished = processors[step](working_data, iterations_per_tick)
    working_data.key = end_key
    if not end_key and (not is_for_n_of or for_n_of_finished) then
      working_data.step = step + 1
    end
  else
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
      num_stations = working_data.num_stations
    }

    -- reset working data
    global.working_data = nil

    -- reset invalidated trains list
    global.active_data.invalidated_trains = {}

    -- start updating GUIs
    global.flags.iterating_ltn_data = false
    global.flags.updating_guis = true
    global.next_update_index = next(global.players)
  end
end

function ltn_data.on_stops_updated(e)
  if global.flags.iterating_ltn_data or global.flags.updating_guis then return end
  global.working_data = {stations = e.logistic_train_stops}
end

function ltn_data.on_dispatcher_updated(e)
  if global.flags.iterating_ltn_data or global.flags.updating_guis then return end
  local stations = global.working_data.stations
  if not stations then
    log("LTN event desync: did not receive stations in time! Skipping iteration.")
    global.working_data = nil
    return
  end

  -- set up working data table
  local data = global.working_data
  data.depots = {}
  data.trains = {}
  data.stations = stations
  data.inventory = {
    provided = {},
    requested = {},
    in_transit = {}
  }
  data.history = table.shallow_copy(global.active_data.history)
  data.alerts = table.shallow_copy(global.active_data.alerts)
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
  data.sorted_stations = {name = {}, status = {}}
  data.sorted_history = {
    depot = {},
    route = {},
    runtime = {},
    finished = {}
  }
  data.sorted_alerts = {
    route = {},
    time = {},
    type = {}
  }
  -- iteration data
  data.step = 1
  data.key = nil -- just for reference
  -- other
  data.aborted_trains = {} -- trains that we aborted on during the iterate_trains step

  -- enable data iteration handler
  global.flags.iterating_ltn_data = true
end

function ltn_data.on_delivery_completed(e)
  local history_to_add = global.active_data.history_to_add
  history_to_add[#history_to_add+1] = {
    finished = game.tick,
    shipment = e.shipment,
    train_id = e.train_id,
    use_working_data = global.flags.iterating_ltn_data or not global.data
  }
end

function ltn_data.on_delivery_failed(e)
  if not global.data then return end

  local trains = global.data.trains
  local train = trains[e.train_id] or trains[global.active_data.invalidated_trains[e.train_id]]

  if train then
    e.planned_shipment = train.shipment
    add_alert(e)
  end
end

local function migrate_train(e, data)
  local trains = data.trains
  local invalidated_trains = global.active_data.invalidated_trains
  local new_train = e.train
  local new_id = new_train.id
  -- migrate train IDs and information
  for i = 1, 2 do
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

function ltn_data.on_train_created(e)
  local data = global.data
  local working_data = global.working_data
  if data then
    migrate_train(e, data)
  end
  if working_data then
    migrate_train(e, working_data)
  end
end

-- ALERTS

ltn_data.on_provider_missing_cargo = add_alert

ltn_data.on_provider_unscheduled_cargo = add_alert

ltn_data.on_requester_remaining_cargo = add_alert

ltn_data.on_requester_unscheduled_cargo = add_alert

-- -----------------------------------------------------------------------------
-- MODULE

ltn_data.alert_types = {}

function ltn_data.init()
  global.data = nil
  global.working_data = nil
  global.active_data = {
    alerts_to_add = {},
    alerts_to_delete = {},
    alerts = queue.new(),
    history_to_add = {},
    history = queue.new(),
    invalidated_trains = {}
  }
  global.flags.iterating_ltn_data = false
  global.flags.updating_guis = false
end

function ltn_data.connect()
  if not remote.interfaces["logistic-train-network"] then
    error("Could not establish connection to LTN!")
  end
  for event_name in pairs(constants.ltn_event_names) do
    local id = remote.call("logistic-train-network", event_name)
    ltn_data.alert_types[id] = string.gsub(event_name, "^on_", "")
    event.register(id, ltn_data[event_name])
  end
  event.on_train_created(ltn_data.on_train_created)
end

return ltn_data