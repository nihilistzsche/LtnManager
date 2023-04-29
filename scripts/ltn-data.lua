local ltn_data = {}

local event = require("__flib__.event")
local queue = require("lib.queue")
local table = require("__flib__.table")
local train_util = require("__flib__.train")

local constants = require("constants")

-- -----------------------------------------------------------------------------
-- HELPER FUNCTIONS

-- add the contents of two material tables together
-- t1 contains the items we are adding into the table, t2 will be returned
local function add_materials(t1, t2)
    for name, count in pairs(t1) do
        local existing = t2[name]
        if existing then
            t2[name] = existing + count
        else
            t2[name] = count
        end
    end
    return t2
end

-- adds the given material to the global inventory
local function add_to_inventory(inventory, surface_index, network_id, name, count)
    for _, surface in ipairs({ -1, surface_index }) do
        local surface_stock = inventory[surface]
        if not surface_stock then
            inventory[surface] = {}
            surface_stock = inventory[surface]
        end
        local material_stock = surface_stock[name]
        if not material_stock then
            surface_stock[name] = { combined_id = 0 }
            material_stock = surface_stock[name]
        end
        material_stock.combined_id = bit32.bor(material_stock.combined_id, network_id)
        material_stock[network_id] = (material_stock[network_id] or 0) + count
    end
end

-- parse the train's status and return metadata related to that status
local function parse_train_status(train_data, translations)
    local train = train_data.train
    local state = train_data.state
    local def = defines.train_state
    if
        train.valid
        and (
            state == def.on_the_path
            or state == def.arrive_signal
            or state == def.wait_signal
            or state == def.arrive_station
        )
    then
        if train_data.returning_to_depot then
            return {
                color = constants.colors.white.tbl,
                msg = translations.returning_to_depot,
                string = translations.returning_to_depot,
            }
        else
            if train_data.pickupDone then
                return {
                    station = "to",
                    string = translations.delivering_to .. " " .. train_data.to,
                    type = translations.delivering_to,
                }
            else
                if not train_data.from then
                    return {
                        color = constants.colors.red.tbl,
                        msg = translations.not_available,
                        string = translations.not_available,
                    }
                else
                    return {
                        station = "from",
                        string = translations.fetching_from .. " " .. train_data.from,
                        type = translations.fetching_from,
                    }
                end
            end
        end
    elseif train.valid and state == def.wait_station then
        if train_data.surface or train_data.returning_to_depot then
            if train_data.has_contents then
                return {
                    color = constants.colors.red.tbl,
                    msg = translations.parked_at_depot_with_residue,
                    string = translations.parked_at_depot_with_residue,
                }
            else
                return {
                    color = constants.colors.green.tbl,
                    msg = translations.parked_at_depot,
                    string = translations.parked_at_depot,
                }
            end
        else
            if train_data.pickupDone then
                return {
                    station = "to",
                    string = translations.unloading_at .. " " .. train_data.to,
                    type = translations.unloading_at,
                }
            else
                local station = train.station
                if station and (station.backer_name or "UNNAMED") == train_data.depot then
                    return {
                        color = constants.colors.yellow.tbl,
                        msg = translations.leaving_depot,
                        string = translations.parked_at_depot,
                    }
                else
                    return {
                        station = "from",
                        string = translations.loading_at .. " " .. train_data.from,
                        type = translations.loading_at,
                    }
                end
            end
        end
    else
        return {
            color = constants.colors.red.tbl,
            msg = translations.not_available,
            string = translations.not_available,
        }
    end
end

-- multi-level next functionality
-- will iterate over the objects table once for each player in the players table
local function per_player_next(players, objects, key, callback)
    key = key or {}
    local player = key.player
    local obj = key.obj

    -- find new keys
    local next_obj = next(objects, key.obj)
    if next_obj and player then
        obj = next_obj
        player = key.player
    else
        obj = next(objects)
        local next_player = next(players, player)
        -- check if the player is ready to be iterated, and if not, keep going until we finish or find a player to process
        while next_player do
            if players[next_player].flags.translations_finished then break end
            next_player = next(players, next_player)
        end
        if next_player and obj then
            player = next_player
        else
            -- we have finished, so return `nil` to cease iteration
            return nil, nil
        end
    end

    -- return tables
    return { player = player, obj = obj }, callback(player, obj)
end

local function add_alert(e)
    -- save train data so it will persist after the delivery is through
    local train_id = e.train_id or e.train.id
    local alert_type = ltn_data.alert_types[e.name]

    -- add common data
    local alert_data = {
        time = game.tick,
        type = alert_type,
        train_id = train_id,
        use_working_data = global.flags.iterating_ltn_data or not global.data,
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
    global.active_data.alerts_to_add[#global.active_data.alerts_to_add + 1] = alert_data
end

-- -----------------------------------------------------------------------------
-- PROCESSORS

local function get_ready_players(working_data)
    local ready_players = {}
    for i, player_table in pairs(global.players) do
        if player_table.flags.translations_finished then ready_players[i] = player_table end
    end

    working_data.players = ready_players
end

local function iterate_stations(working_data, iterations_per_tick)
    local depots = working_data.depots
    local sorted_stations = working_data.sorted_stations
    local trains = working_data.trains

    local inventory = working_data.inventory

    return table.for_n_of(
        working_data.stations,
        working_data.key,
        iterations_per_tick,
        function(station_data, station_id)
            -- check station validity
            if not station_data.entity.valid or not station_data.input.valid or not station_data.output.valid then
                return nil, true
            end

            local network_id = station_data.network_id
            local station_name = station_data.entity.backer_name or "UNNAMED"
            local surface = station_data.entity.surface
            local surface_name = surface.name
            local surface_index = surface.index

            -- generic data
            station_data.name = station_name
            station_data.lowercase_name = string.lower(station_name)
            station_data.surface_index = surface_index

            -- add to surfaces table
            working_data.surfaces[surface_name] = true

            -- get status
            local lamp_signal = station_data.lamp_control.get_control_behavior().get_signal(1)
            local status_color = string.gsub(lamp_signal.signal.name, "signal%-", "")
            station_data.status = {
                color = status_color,
                count = lamp_signal.count,
                sort_key = status_color .. lamp_signal.count,
            }

            -- process station materials
            local provided_requested_count = 0
            for mode, count_multiplier in pairs({ provided = 1, requested = -1 }) do
                local materials = working_data[mode .. "_by_stop"][station_id]
                local materials_copy = {}
                for name, count in pairs(materials or {}) do
                    -- copy
                    materials_copy[name] = count
                    -- update total count
                    provided_requested_count = provided_requested_count + (count * count_multiplier)
                    -- add to global inventory
                    add_to_inventory(inventory[mode], surface_index, network_id, name, count)
                end
                -- add to station
                station_data[mode] = materials_copy
            end
            station_data.provided_requested_count = provided_requested_count

            -- process LTN control signals
            local signals = {}
            local signals_count = 0
            for _, signal in ipairs(station_data.input.get_merged_signals()) do
                local id = signal.signal
                if id.type == "virtual" and constants.ltn_control_signals[id.name] then
                    signals[id.name] = signal.count
                    signals_count = signals_count + signal.count
                end
            end
            station_data.control_signals = signals
            station_data.control_signals_count = signals_count

            -- add station trains to trains table
            local station_trains = station_data.entity.get_train_stop_trains()
            for _, train in ipairs(station_trains) do
                trains[train.id] = { train = train }
            end

            local status = station_data.status
            if station_data.is_depot then
                -- add station to depot
                local depot = depots[station_name]
                if depot then
                    depot.stations[#depot.stations + 1] = station_id
                    local statuses = depot.statuses
                    statuses[status.color] = (statuses[status.color] or 0) + status.count
                    depot.surfaces[surface_index] = true
                else
                    depots[station_name] = {
                        available_trains = {},
                        force = station_data.entity.force,
                        network_id = network_id,
                        num_trains = #station_trains,
                        stations = { station_id },
                        statuses = { [status.color] = status.count },
                        surfaces = { [surface_index] = true },
                    }
                    for _, tbl in pairs(working_data.sorted_depots) do
                        table.insert(tbl, station_name)
                    end
                end
            else
                -- add to sorting tables
                for _, sort_table in pairs(sorted_stations) do
                    sort_table[#sort_table + 1] = station_id
                end
            end

            -- other data (will be populated later)
            station_data.inbound = {}
            station_data.outbound = {}
            station_data.shipments_count = 0
            station_data.search_strings = {}
        end
    )
end

local function iterate_trains(working_data, iterations_per_tick)
    local depots = working_data.depots
    local trains = working_data.trains

    local sorted_trains = working_data.sorted_trains

    local deliveries = working_data.deliveries
    local available_trains = working_data.available_trains

    return table.for_n_of(trains, working_data.key, math.ceil(iterations_per_tick / 2), function(train_data, train_id)
        local train = train_data.train

        -- checks
        local main_locomotive = train.valid and train_util.get_main_locomotive(train)
        if not train.valid or not main_locomotive or not main_locomotive.valid then
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

        -- if `schedule` is `nil`, the train was put into manual mode between the previous step and this one
        if not schedule then return nil, true end

        local depot = schedule.records[1].station
        local depot_data = depots[depot]

        -- not every train will be LTN-controlled
        if not depot_data then return nil, true end

        -- add to depot available trains list
        if train_state == defines.train_state.wait_station and schedule.records[schedule.current].station == depot then
            depot_data.available_trains[#depot_data.available_trains + 1] = train_id
        end

        -- add to sorting tables
        for _, sort_table in pairs(sorted_trains) do
            sort_table[#sort_table + 1] = train_id
        end

        -- construct train contents
        local contents = {}
        local has_contents = false
        for name, count in pairs(train.get_contents()) do
            has_contents = true
            contents["item," .. name] = count
        end
        for name, count in pairs(train.get_fluid_contents()) do
            has_contents = true
            contents["fluid," .. name] = count
        end

        -- construct train data
        train_data.contents = contents
        train_data.has_contents = has_contents
        train_data.state = train_state
        train_data.depot = depot
        train_data.composition = train_util.get_composition_string(train)
        train_data.main_locomotive = main_locomotive
        train_data.search_strings = {}
        train_data.shipment_count = 0
        train_data.surface_index = train_data.main_locomotive.surface.index
        train_data.status = {}
        trains[train_id] = train_data
        for key, value in
            pairs(deliveries[train_id] or available_trains[train_id] or {
                train = train,
                network_id = depot_data.network_id,
                force = depot_data.force,
                returning_to_depot = true,
            })
        do
            train_data[key] = value
        end
    end)
end

local function iterate_in_transit(working_data, iterations_per_tick)
    local in_transit = working_data.inventory.in_transit

    return table.for_n_of(
        working_data.deliveries,
        working_data.key,
        iterations_per_tick,
        function(delivery_data, delivery_id)
            local train_data = working_data.trains[delivery_id]
            if
                train_data
                and train_data.train.valid
                and train_data.main_locomotive
                and train_data.main_locomotive.surface
            then
                local network_id = delivery_data.network_id
                local surface_index = train_data.main_locomotive.surface.index
                -- add to in transit inventory
                for name, count in pairs(delivery_data.shipment) do
                    add_to_inventory(in_transit, surface_index, network_id, name, count)
                end
                -- get shipment sorting value
                local shipment_count = table.reduce(
                    delivery_data.shipment,
                    function(acc, count) return acc + count end,
                    0
                )
                -- add shipment to station
                local stations = working_data.stations
                for station_direction, subtable_name in pairs({ from = "outbound", to = "inbound" }) do
                    local station_data = stations[delivery_data[station_direction .. "_id"]]
                    if station_data then
                        -- add materials
                        add_materials(delivery_data.shipment, station_data[subtable_name])
                        -- update count
                        local multiplier = station_direction == "from" and -1 or 1
                        station_data.shipments_count = station_data.shipments_count + (shipment_count * multiplier)
                    end
                end
                -- add shipment count to train
                train_data.shipment_count = shipment_count
            end
        end
    )
end

local function generate_depot_strings(working_data, iterations_per_tick)
    return table.for_n_of(working_data.depots, working_data.key, iterations_per_tick, function(depot_data, depot_name)
        depot_data.statuses_string = table.reduce(
            depot_data.statuses,
            function(output, count, color) return output .. " " .. color .. " " .. count end
        )
        depot_data.trains_string = #depot_data.available_trains .. " / " .. depot_data.num_trains
        depot_data.statuses_count = table.reduce(depot_data.statuses, function(sum, count) return sum + count end)
        depot_data.search_string = table.concat({
            depot_name,
            depot_data.statuses_string,
            depot_data.trains_string,
        }, " ")
    end)
end

local function sort_depots_by_name(working_data, iterations_per_tick)
    return table.partial_sort(working_data.sorted_depots.name, working_data.key, iterations_per_tick)
end

local function sort_depots_by_network_id(working_data, iterations_per_tick)
    local depots = working_data.depots

    return table.partial_sort(
        working_data.sorted_depots.name,
        working_data.key,
        iterations_per_tick,
        function(depot_1, depot_2) return depots[depot_1].network_id < depots[depot_2].network_id end
    )
end

local function sort_depots_by_statuses(working_data, iterations_per_tick)
    local depots = working_data.depots

    return table.partial_sort(
        working_data.sorted_depots.name,
        working_data.key,
        iterations_per_tick,
        function(depot_1, depot_2) return depots[depot_1].statuses_count < depots[depot_2].statuses_count end
    )
end

local function sort_depots_by_available_trains(working_data, iterations_per_tick)
    local depots = working_data.depots

    return table.partial_sort(
        working_data.sorted_depots.name,
        working_data.key,
        iterations_per_tick,
        function(depot_1, depot_2) return #depots[depot_1].available_trains < #depots[depot_2].available_trains end
    )
end

local function generate_train_statuses(working_data, iterations_per_tick)
    local players = working_data.players
    local trains = working_data.trains

    return table.for_n_of({}, working_data.key, iterations_per_tick, function(data, key)
        local train = trains[key.obj]
        train.status[key.player] = parse_train_status(train, data.translations)
    end, function(_, key)
        return per_player_next(
            players,
            trains,
            key,
            function(player, train)
                return {
                    translations = players[player].dictionaries.gui,
                    train = trains[train],
                }
            end
        )
    end)
end

local function prepare_train_status_sort(working_data)
    working_data.train_status_sort_src = working_data.sorted_trains.status
    working_data.sorted_trains.status = {}
end

local function sort_trains_by_train_id(working_data, iterations_per_tick)
    return table.partial_sort(working_data.sorted_trains.train_id, working_data.key, math.ceil(iterations_per_tick / 2))
end

local function sort_trains_by_status(working_data)
    local players = working_data.players
    local trains = working_data.trains

    return table.for_n_of(players, working_data.key, 1, function(_, player_index)
        local train_ids = table.array_copy(working_data.train_status_sort_src)

        -- TODO: This is bad
        table.sort(
            train_ids,
            function(id_1, id_2)
                return trains[id_1].status[player_index].string < trains[id_2].status[player_index].string
            end
        )

        working_data.sorted_trains.status[player_index] = train_ids
    end)
end

local function sort_trains_by_composition(working_data, iterations_per_tick)
    local trains = working_data.trains
    return table.partial_sort(
        working_data.sorted_trains.composition,
        working_data.key,
        math.ceil(iterations_per_tick / 2),
        function(id_1, id_2) return trains[id_1].composition < trains[id_2].composition end
    )
end

local function sort_trains_by_depot(working_data, iterations_per_tick)
    local trains = working_data.trains
    return table.partial_sort(
        working_data.sorted_trains.depot,
        working_data.key,
        math.ceil(iterations_per_tick / 2),
        function(id_1, id_2) return trains[id_1].depot < trains[id_2].depot end
    )
end

local function sort_trains_by_shipment(working_data, iterations_per_tick)
    local trains = working_data.trains
    return table.partial_sort(
        working_data.sorted_trains.shipment,
        working_data.key,
        math.ceil(iterations_per_tick / 2),
        function(id_1, id_2) return trains[id_1].shipment_count < trains[id_2].shipment_count end
    )
end

local function generate_train_search_strings(working_data)
    local players = working_data.players
    local trains = working_data.trains

    return table.for_n_of({}, working_data.key, 1, function(data)
        local train_data = data.train
        local translations = data.translations

        local str = { string.lower(train_data.depot), string.lower(train_data.status[data.player_index].string) }
        for name in pairs(train_data.contents or {}) do
            table.insert(str, string.lower(translations[name]))
        end

        train_data.search_strings[data.player_index] = table.concat(str, " ")
    end, function(_, key)
        return per_player_next(
            players,
            trains,
            key,
            function(player, train)
                return {
                    train = trains[train],
                    player_index = player,
                    translations = players[player].dictionaries.materials,
                }
            end
        )
    end)
end

local function generate_station_search_strings(working_data)
    local players = working_data.players
    local stations = working_data.stations

    local subtables = {
        provided = "materials",
        requested = "materials",
        inbound = "materials",
        outbound = "materials",
        control_signals = "virtual_signals",
    }

    return table.for_n_of({}, working_data.key, 1, function(data)
        local station_data = data.station
        local translations = data.translations

        local str = { string.lower(station_data.name) or "" }
        local str_i = 1
        for station_table, dictionary_name in pairs(subtables) do
            local dictionary = translations[dictionary_name]
            for name in pairs(station_data[station_table] or {}) do
                str_i = str_i + 1
                str[str_i] = string.lower(dictionary[name] or name)
            end
        end

        station_data.search_strings[data.player_index] = table.concat(str, " ")
    end, function(_, key)
        return per_player_next(
            players,
            stations,
            key,
            function(player, station)
                return {
                    station = stations[station],
                    player_index = player,
                    translations = players[player].dictionaries,
                }
            end
        )
    end)
end

local function sort_stations_by_name(working_data, iterations_per_tick)
    local stations = working_data.stations
    return table.partial_sort(
        working_data.sorted_stations.name,
        working_data.key,
        math.ceil(iterations_per_tick / 2),
        function(id_1, id_2) return stations[id_1].lowercase_name < stations[id_2].lowercase_name end
    )
end

local function sort_stations_by_status(working_data, iterations_per_tick)
    local stations = working_data.stations
    return table.partial_sort(
        working_data.sorted_stations.status,
        working_data.key,
        math.ceil(iterations_per_tick / 2),
        function(id_1, id_2) return stations[id_1].status.sort_key < stations[id_2].status.sort_key end
    )
end

local function sort_stations_by_network_id(working_data, iterations_per_tick)
    local stations = working_data.stations
    return table.partial_sort(
        working_data.sorted_stations.network_id,
        working_data.key,
        math.ceil(iterations_per_tick / 2),
        function(id_1, id_2) return stations[id_1].network_id < stations[id_2].network_id end
    )
end

local function sort_stations_by_provided_requested(working_data, iterations_per_tick)
    local stations = working_data.stations
    return table.partial_sort(
        working_data.sorted_stations.provided_requested,
        working_data.key,
        math.ceil(iterations_per_tick / 2),
        function(id_1, id_2) return stations[id_1].provided_requested_count < stations[id_2].provided_requested_count end
    )
end

local function sort_stations_by_shipments(working_data, iterations_per_tick)
    local stations = working_data.stations
    return table.partial_sort(
        working_data.sorted_stations.shipments,
        working_data.key,
        math.ceil(iterations_per_tick / 2),
        function(id_1, id_2) return stations[id_1].shipments_count < stations[id_2].shipments_count end
    )
end

local function sort_stations_by_control_signals(working_data, iterations_per_tick)
    local stations = working_data.stations
    return table.partial_sort(
        working_data.sorted_stations.control_signals,
        working_data.key,
        math.ceil(iterations_per_tick / 2),
        function(id_1, id_2) return stations[id_1].control_signals_count < stations[id_2].control_signals_count end
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
        -- Also check for an invalid or nonexistent main locomotive
        if train.started and train.main_locomotive and train.main_locomotive.valid then
            -- add remaining info
            entry.from = train.from
            entry.to = train.to
            entry.from_id = train.from_id
            entry.to_id = train.to_id
            entry.network_id = train.network_id
            entry.depot = train.depot
            entry.route = train.from .. " -> " .. train.to
            entry.runtime = entry.finished - train.started
            entry.surface_index = train.main_locomotive.surface.index
            entry.search_strings = {}
            entry.shipment_count = table.reduce(entry.shipment, function(acc, count) return acc + count end, 0)
            -- add to history
            queue.push_right(active_history, entry)
            -- limit number of entries
            for _ = 1, queue.length(active_history) - settings.global["ltnm-history-length"].value do
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
        history_ids[#history_ids + 1] = i
    end
    -- copy to each table
    for key in pairs(sorted_history) do
        sorted_history[key] = table.array_copy(history_ids)
    end
end

local function generate_history_search_strings(working_data)
    local players = working_data.players
    local history = working_data.history

    return table.for_n_of({}, working_data.key, 1, function(data, key)
        if key.obj == "first" or key.obj == "last" then return end

        local history_data = data.history
        local translations = data.translations

        local str = {
            string.lower(history_data.depot),
            string.lower(history_data.from),
            string.lower(history_data.to),
        }
        local str_i = 3
        for name in pairs(history_data.shipment) do
            str_i = str_i + 1
            str[str_i] = string.lower(translations[name])
        end

        history_data.search_strings[data.player_index] = table.concat(str, " ")
    end, function(_, key)
        return per_player_next(
            players,
            history,
            key,
            function(player, history_index)
                return {
                    history = history[history_index],
                    player_index = player,
                    translations = players[player].dictionaries.materials,
                }
            end
        )
    end)
end

local function sort_history(working_data, iterations_per_tick)
    local history = working_data.history
    local sorted_history = working_data.sorted_history

    local key = working_data.key or { sort = next(sorted_history) }
    local sort = key.sort

    local next_index = table.partial_sort(
        sorted_history[key.sort],
        key.index,
        math.ceil(iterations_per_tick / 2),
        function(id_1, id_2)
            if sort == "shipment" then
                return history[id_1].shipment_count < history[id_2].shipment_count
            else
                return history[id_1][sort] < history[id_2][sort]
            end
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
        flags.deleted_all_alerts = false
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
        alert_data.search_strings = {}
        alert_data.train = {
            depot = train.depot,
            from = train.from,
            from_id = train.from_id,
            id = alert_data.train_id,
            network_id = train.network_id,
            pickup_done = train.pickupDone or false,
            to = train.to,
            to_id = train.to_id,
            route = train.from .. " -> " .. train.to,
            surface_index = train.surface_index,
        }
        -- save to alerts table
        queue.push_right(active_alerts, alert_data)
        -- limit to 30 entries
        if queue.length(active_alerts) > 30 then queue.pop_left(active_alerts) end
        ::continue::
    end
    active_data.alerts_to_add = {}
end

local function generate_alerts_search_strings(working_data)
    local players = working_data.players
    local alerts = working_data.alerts

    return table.for_n_of({}, working_data.key, 1, function(data, key)
        if key.obj == "first" or key.obj == "last" then return end

        local alert_data = data.alert
        local translations = data.translations

        -- TODO: Search alert types
        local str = {
            alert_data.time,
            alert_data.train_id,
            string.lower(alert_data.train.from),
            string.lower(alert_data.train.to),
            alert_data.train.network_id,
        }
        local str_i = 5
        for _, source in pairs({ alert_data.planned_shipment or {}, alert_data.actual_shipment }) do
            for name in pairs(source) do
                if translations[name] then
                    str_i = str_i + 1
                    str[str_i] = string.lower(translations[name])
                end
            end
        end

        alert_data.search_strings[data.player_index] = table.concat(str, " ")
    end, function(_, key)
        return per_player_next(
            players,
            alerts,
            key,
            function(player, alerts_index)
                return {
                    alert = alerts[alerts_index],
                    player_index = player,
                    translations = players[player].dictionaries.materials,
                }
            end
        )
    end)
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
        alert_ids[#alert_ids + 1] = i
    end
    -- copy to each table
    for key in pairs(sorted_alerts) do
        sorted_alerts[key] = table.array_copy(alert_ids)
    end
end

local function sort_alerts(working_data, iterations_per_tick)
    local alerts = working_data.alerts
    local sorted_alerts = working_data.sorted_alerts

    local key = working_data.key or { sort = next(sorted_alerts) }
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

local function process_surfaces(working_data)
    local surface_data = {
        items = { { "gui.ltnm-all-paren" } },
        selected_to_index = { -1 },
    }
    local i = 1
    local surfaces = game.surfaces
    for surface_name in pairs(working_data.surfaces) do
        if surfaces[surface_name] then
            i = i + 1
            surface_data.items[i] = surface_name
            surface_data.selected_to_index[i] = surfaces[surface_name].index
        end
    end

    working_data.surfaces = surface_data
end

-- -----------------------------------------------------------------------------
-- HANDLERS

function ltn_data.iterate()
    local working_data = global.working_data
    local step = working_data.step

    -- this value will be adjusted per step based on the performance impact
    local iterations_per_tick = settings.global["ltnm-iterations-per-tick"].value

    local processors = {
        get_ready_players,
        iterate_stations,
        iterate_trains,
        iterate_in_transit,
        generate_depot_strings,
        sort_depots_by_name,
        sort_depots_by_network_id,
        sort_depots_by_statuses,
        sort_depots_by_available_trains,
        generate_train_statuses,
        prepare_train_status_sort,
        sort_trains_by_train_id,
        sort_trains_by_status,
        sort_trains_by_composition,
        sort_trains_by_depot,
        sort_trains_by_shipment,
        generate_train_search_strings,
        generate_station_search_strings,
        sort_stations_by_name,
        sort_stations_by_status,
        sort_stations_by_network_id,
        sort_stations_by_provided_requested,
        sort_stations_by_shipments,
        sort_stations_by_control_signals,
        update_history,
        prepare_history_sort,
        generate_history_search_strings,
        sort_history,
        update_alerts,
        generate_alerts_search_strings,
        prepare_alerts_sort,
        sort_alerts,
        process_surfaces,
    }

    if processors[step] then
        local end_key, is_for_n_of, for_n_of_finished = processors[step](working_data, iterations_per_tick)
        working_data.key = end_key
        if not end_key and (not is_for_n_of or for_n_of_finished) then working_data.step = step + 1 end
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
            surfaces = working_data.surfaces,
            -- sorting tables
            sorted_trains = working_data.sorted_trains,
            sorted_depots = working_data.sorted_depots,
            sorted_stations = working_data.sorted_stations,
            sorted_history = working_data.sorted_history,
            sorted_alerts = working_data.sorted_alerts,
        }

        -- reset working data
        global.working_data = nil

        -- reset invalidated trains list
        global.active_data.invalidated_trains = {}

        -- start updating GUIs
        global.flags.iterating_ltn_data = false
        if table_size(working_data.players) > 0 then
            global.flags.updating_guis = true
            global.next_update_index = next(working_data.players)
        end
    end
end

function ltn_data.on_stops_updated(e)
    if global.flags.iterating_ltn_data or global.flags.updating_guis then return end
    global.working_data = { stations = e.logistic_train_stops }
end

function ltn_data.on_dispatcher_updated(e)
    if global.flags.iterating_ltn_data or global.flags.updating_guis then return end
    local working_data = global.working_data
    if not working_data then
        log("LTN event desync: did not receive stations in time! Skipping iteration.")
        return
    end
    local stations = global.working_data.stations

    -- set up working data table
    working_data.depots = {}
    working_data.trains = {}
    working_data.stations = stations
    working_data.inventory = {
        provided = {},
        requested = {},
        in_transit = {},
    }
    working_data.history = table.shallow_copy(global.active_data.history)
    working_data.alerts = table.shallow_copy(global.active_data.alerts)
    -- data tables
    working_data.provided_by_stop = e.provided_by_stop
    working_data.requested_by_stop = e.requests_by_stop
    working_data.deliveries = e.deliveries
    working_data.available_trains = e.available_trains
    -- lookup tables
    working_data.surfaces = {}
    -- sorting tables
    working_data.sorted_trains = {
        train_id = {},
        status = {},
        composition = {},
        depot = {},
        shipment = {},
    }
    working_data.sorted_depots = {
        name = {},
        network_id = {},
        status = {},
        trains = {},
    }
    working_data.sorted_stations = {
        name = {},
        status = {},
        network_id = {},
        provided_requested = {},
        shipments = {},
        control_signals = {},
    }
    working_data.sorted_history = {
        depot = {},
        train_id = {},
        network_id = {},
        route = {},
        finished = {},
        runtime = {},
        shipment = {},
    }
    working_data.sorted_alerts = {
        time = {},
        train_id = {},
        route = {},
        network_id = {},
        type = {},
    }
    -- iteration data
    working_data.step = 1
    working_data.key = nil -- just for reference
    -- other
    working_data.aborted_trains = {} -- trains that we aborted on during the iterate_trains step

    -- enable data iteration handler
    global.flags.iterating_ltn_data = true
end

function ltn_data.on_delivery_completed(e)
    local history_to_add = global.active_data.history_to_add
    history_to_add[#history_to_add + 1] = {
        finished = game.tick,
        shipment = e.shipment,
        train_id = e.train_id,
        use_working_data = global.flags.iterating_ltn_data or not global.data,
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
        local old_id = e["old_train_id_" .. i]
        if old_id then
            local train_data = trains[old_id] or trains[invalidated_trains[old_id]]
            if train_data then
                -- add a mapping for alerts
                invalidated_trains[new_id] = invalidated_trains[old_id] or old_id
                invalidated_trains[old_id] = nil
                -- replace train and main_locomotive, the actual IDs and such will be updated on the next LTN update cycle
                train_data.train = new_train
                train_data.main_locomotive = train_util.get_main_locomotive(new_train)
            end
        end
    end
end

function ltn_data.on_train_created(e)
    local data = global.data
    local working_data = global.working_data
    if data then migrate_train(e, data) end
    if working_data then migrate_train(e, working_data) end
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
        invalidated_trains = {},
    }
    global.flags.iterating_ltn_data = false
    global.flags.updating_guis = false
end

function ltn_data.connect()
    if not remote.interfaces["logistic-train-network"] then error("Could not establish connection to LTN!") end
    for event_name in pairs(constants.ltn_event_names) do
        local id = remote.call("logistic-train-network", event_name)
        ltn_data.alert_types[id] = string.gsub(event_name, "^on_", "")
        event.register(id, ltn_data[event_name])
    end
    event.on_train_created(ltn_data.on_train_created)
end

return ltn_data
