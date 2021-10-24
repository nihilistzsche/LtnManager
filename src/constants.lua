local constants = {}

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
    trains = {
      minimap = 90,
      status = 250,
      composition = 120,
      depot = 100,
      shipment = 36 * 4,
    },
    -- stations_list = {
    --   name = 232,
    --   status = 53,
    --   network_id = 84,
    --   provided_requested = (36 * 6),
    --   shipments = (36 * 5),
    --   control_signals = (36 * 7)
    -- },
    -- history = {
    --   depot = 160,
    --   train_id = 60,
    --   network_id = 84,
    --   route = 351,
    --   runtime = 68,
    --   finished = 68,
    --   shipment = (36 * 6)
    -- }
  }
}

constants.gui_translations = {
  delivering_to = {"gui.ltnm-delivering-to"},
  fetching_from = {"gui.ltnm-fetching-from"},
  loading_at = {"gui.ltnm-loading-at"},
  parked_at_depot = {"gui.ltnm-parked-at-depot"},
  returning_to_depot = {"gui.ltnm-returning-to-depot"},
  unloading_at = {"gui.ltnm-unloading-at"},
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

return constants
