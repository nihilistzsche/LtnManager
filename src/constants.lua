local constants = {}

-- colors
constants.station_indicator_color = {r=1, g=0.2, b=0.2, a=0.75}

-- gui
constants.action_buttons_width = 96
constants.main_frame_height = 615
constants.main_frame_width = 830
constants.search_frame_height = 40

-- other
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
  on_delivery_failed = true
}

-- sorts
constants.alerts_sorts = {
  network_id = true,
  route = true,
  time = true,
  type = true
}
constants.history_sorts = {
  depot = true,
  route = true,
  runtime = true,
  finished = true
}

return constants
