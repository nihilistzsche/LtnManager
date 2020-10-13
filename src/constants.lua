local constants = {}

if script then
  local event = require("__flib__.event")

  constants.events = {
    close_main_gui = event.generate_id(),
    update_main_gui = event.generate_id()
  }
end

constants.colors = {
  green = {
    str = "69, 255, 69",
    tbl = {69, 255, 69}
  },
  info = {
    str = "128, 206, 240",
    tbl = {128, 206, 240}
  },
  red = {
    str = "255, 69, 69",
    tbl = {255, 69, 69}
  },
  station_circle = {
    str = "255, 50, 50, 190",
    tbl = {255, 50, 50, 190}
  },
  yellow = {
    str = "255, 240, 69",
    tbl = {255, 240, 69}
  },
  white = {
    str = "255, 255, 255",
    tbl = {255, 255, 255}
  }
}

-- dictionary locale identifier -> dictionary of hardcoded GUI sizes
constants.gui = {
  en = {
    trains_list = {
      composition = 240,
      status = 373,
      shipment = (36 * 6)
    },
    stations_list = {
      name = 232,
      status = 53,
      network_id = 84,
      provided_requested = (36 * 6),
      shipments = (36 * 5),
      control_signals = (36 * 7)
    },
    history = {
      depot = 100,
      train_id = 100,
      network_id = 100,
      route = 100,
      finished = 100,
      runtime = 100,
      shipment = 100
    }
  }
}

constants.input_sanitizers = {
  ["%("] = "%%(",
  ["%)"] = "%%)",
  ["%.^[%*]"] = "%%.",
  ["%+"] = "%%+",
  ["%-"] = "%%-",
  ["^[%.]%*"] = "%%*",
  ["%?"] = "%%?",
  ["%["] = "%%[",
  ["%]"] = "%%]",
  ["%^"] = "%%^",
  ["%$"] = "%%$"
}

constants.ltn_control_signals = {
  ["ltn-depot"] = true,
  ["ltn-depot-priority"] = true,
  -- excluded because it's shown as a separate column
  -- ["ltn-network-id"] = true,
  ["ltn-min-train-length"] = true,
  ["ltn-max-train-length"] = true,
  ["ltn-max-trains"] = true,
  ["ltn-provider-threshold"] = true,
  ["ltn-provider-stack-threshold"] = true,
  ["ltn-provider-priority"] = true,
  ["ltn-locked-slots"] = true,
  ["ltn-requester-threshold"] = true,
  ["ltn-requester-stack-threshold"] = true,
  ["ltn-requester-priority"] = true,
  ["ltn-disable-warnings"] = true
}

constants.ltn_event_names = {
  on_stops_updated = true,
  on_dispatcher_updated = true,
  -- on_delivery_pickup_complete = true,
  on_delivery_completed = true,
  on_delivery_failed = true,
  -- on_dispatcher_no_train_found = true,
  on_provider_missing_cargo = true,
  on_provider_unscheduled_cargo = true,
  on_requester_remaining_cargo = true,
  on_requester_unscheduled_cargo = true
}

constants.max_slot_table_height = 3

return constants
