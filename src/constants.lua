local constants = {}

constants.colors = {
  error = {
    str = "255, 90, 90",
    tbl = {255, 90, 90}
  },
  green = {
    str = "210, 253, 145",
    tbl = {210, 253, 145}
  },
  heading = {
    str = "255, 230, 192",
    tbl = {255, 230, 192}
  },
  info = {
    str = "128, 206, 240",
    tbl = {128, 206, 240}
  },
  station_circle = {
    str = "255, 50, 50, 190",
    tbl = {255, 50, 50, 190}
  },
  unresearched = {
    str = "255, 142, 142",
    tbl = {255, 142, 142}
  }
}

constants.gui = {
  action_buttons_width = 96,
  main_frame_height = 615,
  main_frame_width = 830,
  search_frame_height = 40
}

constants.input_sanitisers = {
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

constants.ltn_event_names = {
  on_stops_updated = true,
  on_dispatcher_updated = true,
  -- on_delivery_pickup_complete = true,
  on_delivery_completed = true,
  on_delivery_failed = true,
  -- alerts
  -- on_dispatcher_no_train_found = true,
  on_provider_missing_cargo = true,
  on_provider_unscheduled_cargo = true,
  on_requester_remaining_cargo = true,
  on_requester_unscheduled_cargo = true
}

return constants
