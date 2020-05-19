return {
  -- colors
  station_indicator_color = {r=1, g=0.2, b=0.2, a=0.75},
  -- gui
  action_buttons_width = 96,
  main_frame_height = 615,
  main_frame_width = 830,
  search_frame_height = 40,
  -- other
  ltn_event_names = {
    on_stops_updated = true,
    on_dispatcher_updated = true,
    -- on_dispatcher_no_train_found = true,
    on_delivery_pickup_complete = true,
    on_delivery_completed = true,
    on_delivery_failed = true
  }
}