-- -------------------------------------------------------------------------------------------------------------------------------------------------------------
-- LTN DATA MANAGER
-- Takes in data from LTN and parses it for use by the GUI
-- This script is the only place to touch LTN data, the rest of the mod uses the data that this script produces.

-- dependencies
local event = require("__RaiLuaLib__.lualib.event")
local util = require("scripts.util")

-- locals
local math_floor = math.floor
local table_insert = table.insert
local table_remove = table.remove
local table_sort = table.sort

local ltn_event_ids = {}

-- scripts
local alert_popup_gui = require("gui.alert-popup")

-- object
local data_manager = {}

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
  local num_to_iterate = settings.global["ltnm-stations-per-tick"].value
  local end_index = index + num_to_iterate

  for i=index,end_index do
    local station_id = station_ids[i]
    local station = stations[station_id]
    if not station then error("Station ID mismatch") end

    if station.entity.valid and station.input.valid then
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
          train_data.main_locomotive = util.train.get_main_locomotive(train)
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
          depots[station_name] = {available_trains=station_available_trains, num_trains=#station_train_ids, stations={station_id},
            trains_temp=station_train_ids}
        end
      end

      -- process station materials
      for _,mode in ipairs{"provided", "requested"} do
        local materials = data[mode.."_by_stop"][station_id]
        if materials then
          -- add to station
          station[mode] = table.deepcopy(materials)
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
    end

    -- end this step if we are done
    if i == num_stations then
      data.step = 2
      return
    end
  end

  data.index = end_index + 1
end

local function process_in_transit_materials(data)
  local in_transit = data.inventory.in_transit
  local material_locations = data.material_locations
  for id,t in pairs(data.deliveries) do
    -- add to in transit inventory
    in_transit[t.network_id] = util.add_materials(t.shipment, in_transit[t.network_id] or {})
    -- sort materials into locations
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
end

local function sort_depot_trains(data)
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
        if train.train.valid then
          local lookup = sort_lookup[train.composition]
          if lookup then
            lookup[#lookup+1] = train_id
          else
            sort_lookup[train.composition] = {train_id}
          end
          table_insert(sort_values, train.composition)
        end
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
        if player_table.flags.translations_finished then
          local sort_lookup = {}
          local sort_values = {}
          local translations = player_table.dictionary.gui.translations
          -- sort trains
          for _,train_id in ipairs(depot.trains_temp) do
            local train = trains[train_id]
            if train.train.valid then
              local status, status_data = util.train.get_status_string(train, translations)
              -- add status to train data
              train.status[pi] = status_data
              -- add to sorting tables
              local lookup = sort_lookup[status]
              if lookup then
                lookup[#lookup+1] = train_id
              else
                sort_lookup[status] = {train_id}
              end
              table_insert(sort_values, status)
            end
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
    depot.trains_temp = nil
  end

  -- next step
  data.step = 4
end

local function sort_stations(data)
  -- sorting tables
  local sort = {
    name = {lookup={}, values={}},
    network_id = {lookup={}, values={}},
    status = {lookup={}, values={}},
  }

  -- iterate stations
  for station_id,station_data in pairs(data.stations) do
    if station_data.entity.valid then
      if not station_data.isDepot then
        -- organize station data
        local station = {
          name = station_data.entity.backer_name,
          network_id = station_data.network_id,
          status = station_data.status.name.."_"..station_data.status.count
        }
        -- sort data
        for key,t in pairs(sort) do
          local value = station[key]
          local lookup = t.lookup[value]
          if lookup then
            lookup[#lookup+1] = station_id
          else
            t.lookup[value] = {station_id}
          end
          table_insert(t.values, value)
        end
      end
    end
  end

  -- sort data
  local results = {}
  for key,t in pairs(sort) do
    local result = {}
    local lookup = t.lookup
    local values = t.values
    table_sort(values)
    for i,value in ipairs(values) do
      result[i] = table_remove(lookup[value])
    end
    results[key] = result
  end

  -- save data
  data.sorted_stations = results

  -- next step
  data.step = 5
end

local function sort_history(data)
  -- sorting tables
  local sort = {
    depot = {lookup={}, values={}},
    route = {lookup={}, values={}},
    network_id = {lookup={}, values={}},
    runtime = {lookup={}, values={}},
    finished = {lookup={}, values={}}
  }

  -- iterate history to fill sorting tables
  for i,entry in ipairs(data.history) do
    for sort_type,sort_table in pairs(sort) do
      local value
      if sort_type == "route" then
        value = entry.from.." -> "..entry.to
      else
        value = entry[sort_type]
      end
      local lookup = sort_table.lookup[value]
      if lookup then
        lookup[#lookup+1] = i
      else
        sort_table.lookup[value] = {i}
      end
      sort_table.values[#sort_table.values+1] = value
    end
  end

  -- sort and output
  local output = {}
  for sort_type,sort_table in pairs(sort) do
    local lookup = sort_table.lookup
    local values = sort_table.values
    local out = {}
    table_sort(values)
    for i,value in ipairs(values) do
      out[i] = table_remove(lookup[value])
    end
    output[sort_type] = out
  end

  -- save data
  data.sorted_history = output

  -- next step
  data.step = 6
end

local function sort_alerts(data)
  -- sorting tables
  local sort = {
    network_id = {lookup={}, values={}},
    route = {lookup={}, values={}},
    time = {lookup={}, values={}},
    type = {lookup={}, values={}}
  }

  local alerts = data.alerts

  -- remove alerts
  local to_delete = global.data and global.data.alerts_to_delete or {}
  for id,_ in pairs(to_delete) do
    alerts[id] = nil
  end

  -- iterate history to fill sorting tables
  for i,entry in pairs(data.alerts) do
    if i ~= "_index" then
      for sort_type,sort_table in pairs(sort) do
        local value
        if sort_type == "network_id" then
          value = entry.train.network_id
        elseif sort_type == "route" then
          value = entry.train.from.." -> "..entry.train.to
        else
          value = entry[sort_type]
        end
        local lookup = sort_table.lookup[value]
        if lookup then
          lookup[#lookup+1] = i
        else
          sort_table.lookup[value] = {i}
        end
        sort_table.values[#sort_table.values+1] = value
      end
    end
  end

  -- sort and output
  local output = {}
  for sort_type,sort_table in pairs(sort) do
    local lookup = sort_table.lookup
    local values = sort_table.values
    local out = {}
    table_sort(values)
    for i,value in ipairs(values) do
      out[i] = table_remove(lookup[value])
    end
    output[sort_type] = out
  end

  -- save data
  data.sorted_alerts = output

  -- next step
  data.step = 100
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
    process_in_transit_materials(data)
  elseif step == 3 then
    sort_depot_trains(data)
  elseif step == 4 then
    sort_stations(data)
  elseif step == 5 then
    sort_history(data)
  elseif step == 6 then
    sort_alerts(data)
  elseif step == 100 then
    -- output data
    global.data = {
      -- bulk data
      depots = data.depots,
      stations = data.stations,
      inventory = data.inventory,
      trains = data.trains,
      history = data.history,
      alerts = data.alerts,
      -- lookup tables
      sorted_stations = data.sorted_stations,
      network_to_stations = data.network_to_stations,
      material_locations = data.material_locations,
      sorted_history = data.sorted_history,
      sorted_alerts = data.sorted_alerts,
      -- other
      num_stations = data.num_stations,
      alerts_to_delete = {},
      invalidated_trains = {}
    }

    -- avoid crashing
    if global.working_data.alert_popups == nil then
      global.working_data.alert_popups = {};
    end

    -- create alert popups
    for _,t in pairs(global.working_data.alert_popups) do
      alert_popup_gui.create_for_all(t)
    end

    -- reset working data
    global.working_data = {
      history = global.working_data.history,
      alerts = global.working_data.alerts,
      alert_popups = {}
    }

    -- reset events
    event.enable("ltn_on_stops_updated")
    event.enable("ltn_on_dispatcher_updated")
    event.disable("iterate_ltn_data")
  end
end

local function on_stops_updated(e)
  global.working_data.stations = e.logistic_train_stops
end

local function on_dispatcher_updated(e)
  local stations = global.working_data.stations
  if not stations then
    log("LTN event desync: did not receive stations in time! Skipping iteration.")
    global.working_data.stations = nil
    return
  end

  -- deregister events for this update cycle
  event.disable("ltn_on_stops_updated")
  event.disable("ltn_on_dispatcher_updated")

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
  event.enable("iterate_ltn_data")
end

local function on_delivery_pickup_complete(e)
  if not global.data then return end

  -- compare shipments to see if something was loaded incorrectly
  for name,count in pairs(e.actual_shipment) do
    if not e.planned_shipment[name] or math_floor(e.planned_shipment[name]) > math_floor(count) then
      -- save train data so it will persist after the delivery is through
      local train = global.data.trains[e.train_id]
      if not train then error("Could not find train of ID: "..e.train_id) end
      local alerts = global.working_data.alerts
      alerts._index = alerts._index + 1
      alerts[alerts._index] = {
        time = game.tick,
        type = "incorrect_pickup",
        train = {
          depot = train.depot,
          from = train.from,
          from_id = train.from_id,
          id = e.train_id,
          network_id = train.network_id,
          pickup_done = train.pickupDone or false,
          to = train.to,
          to_id = train.to_id
        },
        planned_shipment = e.planned_shipment,
        actual_shipment = e.actual_shipment
      }
      global.working_data.alert_popups[#global.working_data.alert_popups+1] = {id=alerts._index, type="incorrect_pickup"}
    end
  end
end

local function on_delivery_completed(e)
  if not global.data then return end
  local train = global.data.trains[e.train_id]
  if not train then error("Could not find train of ID: "..e.train_id) end

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
    finished = game.tick
  })
  global.working_data.history[51] = nil -- limit to 50 entries

  -- detect incomplete deliveries
  local contents = {}
  for n,c in pairs(train.train.get_contents()) do
    contents["item,"..n] = c
  end
  for n,c in pairs(train.train.get_fluid_contents()) do
    contents["fluid,"..n] = c
  end
  if table_size(contents) > 0 then
    local alerts = global.working_data.alerts
    alerts._index = alerts._index + 1
    alerts[alerts._index] = {
      time = game.tick,
      type = "incomplete_delivery",
      train = {
        depot = train.depot,
        from = train.from,
        from_id = train.from_id,
        id = e.train_id,
        network_id = train.network_id,
        to = train.to,
        to_id = train.to_id
      },
      shipment = e.shipment,
      leftovers = contents
    }
    global.working_data.alert_popups[#global.working_data.alert_popups+1] = {id=alerts._index, type="incomplete_delivery"}
  end
end

local function on_dispatcher_no_train_found(e)
  local breakpoint
end

local function on_delivery_failed(e)
  if not global.data then return end

  local alerts = global.working_data.alerts
  alerts._index = alerts._index + 1
  local alert_type

  local trains = global.data.trains

  local train = trains[e.train_id] or trains[global.data.invalidated_trains[e.train_id]]
  if train.train.valid then
    alert_type = "delivery_timed_out"
  else
    alert_type = "train_invalidated"
  end

  alerts[alerts._index] = {
    time = game.tick,
    type = alert_type,
    train = {
      depot = train.depot,
      from = train.from,
      from_id = train.from_id,
      id = e.train_id,
      network_id = train.network_id,
      to = train.to,
      to_id = train.to_id
    },
    shipment = train.shipment
  }
  global.working_data.alert_popups[#global.working_data.alert_popups+1] = {id=alerts._index, type=alert_type}
end

local function on_train_created(e)
  if not global.data then return end
  local trains = global.data.trains
  local invalidated_trains = global.data.invalidated_trains
  local new_train = e.train
  local new_id = new_train.id
  -- migrate train IDs and information
  for i=1,2 do
    local old_id = e["old_train_id_"..i]
    if old_id then
      local train_data = trains[old_id]
      if train_data or invalidated_trains[old_id] then
        -- add a mapping for alerts
        invalidated_trains[new_id] = invalidated_trains[old_id] or old_id
        invalidated_trains[old_id] = nil
      end
      if train_data then
        -- replace train and main_locomotive, the actual IDs and such will be updated on the next LTN update cycle
        train_data.train = new_train
        train_data.main_locomotive = util.train.get_main_locomotive(new_train)
      end
    end
  end
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
  if not remote.interfaces["logistic-train-network"] then
    error("Could not establish connection to LTN!")
  end
  local events = {}
  for id,handler in pairs(ltn_handlers) do
    ltn_event_ids[id] = remote.call("logistic-train-network", id)
    events["ltn_"..id] = {id=ltn_event_ids[id], handler=handler, group="ltn"}
  end
  events.on_train_created = {id=defines.events.on_train_created, handler=on_train_created, group="ltn"}
  events.iterate_ltn_data = {id=defines.events.on_tick, handler=iterate_data, options={skip_validation=true}}
  event.register_conditional(events)
end

-- -----------------------------------------------------------------------------

data_manager.ltn_event_ids = ltn_event_ids

return data_manager