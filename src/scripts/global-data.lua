local global_data = {}

function global_data.init()
  global_data.build_translations()
  global.flags = {
    deleted_all_alerts = false,
    deleted_history = false,
    iterating_ltn_data = false,
    updating_guis = false,
  }
  global.players = {}
end

function global_data.build_translations()
  local translation_data = {
    -- train status
    {dictionary = "gui", internal = "count", localised = {"ltnm-gui.count-label"}},
    {dictionary = "gui", internal = "delivering_to", localised = {"ltnm-gui.delivering-to-label"}},
    {dictionary = "gui", internal = "fetching_from", localised = {"ltnm-gui.fetching-from-label"}},
    {dictionary = "gui", internal = "leaving_depot", localised = {"ltnm-gui.leaving-depot"}},
    {dictionary = "gui", internal = "loading_at", localised = {"ltnm-gui.loading-at-label"}},
    {dictionary = "gui", internal = "locale_identifier", localised = {"locale-identifier"}},
    {dictionary = "gui", internal = "not_available", localised = {"ltnm-gui.not-available"}},
    {
      dictionary = "gui",
      internal = "parked_at_depot_with_residue",
      localised = {"ltnm-gui.parked-at-depot-with-residue"}
    },
    {dictionary = "gui", internal = "parked_at_depot", localised = {"ltnm-gui.parked-at-depot"}},
    {dictionary = "gui", internal = "returning_to_depot", localised = {"ltnm-gui.returning-to-depot"}},
    {dictionary = "gui", internal = "unloading_at", localised = {"ltnm-gui.unloading-at-label"}}
  }
  -- materials
  for _, type in ipairs{"fluid", "item"} do
    local prefix = type..","
    for name, prototype in pairs(game[type.."_prototypes"]) do
      translation_data[#translation_data+1] = {
        dictionary = "materials",
        internal = prefix..name,
        localised = prototype.localised_name
      }
    end
  end
  -- virtual signals
  for name, prototype in pairs(game.virtual_signal_prototypes) do
    translation_data[#translation_data+1] = {
      dictionary = "virtual_signals",
      internal = name,
      localised = prototype.localised_name
    }
  end
  global.translation_data = translation_data
end

return global_data