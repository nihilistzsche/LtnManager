local global_data = {}

function global_data.init()
  global_data.build_translations()
  global.flags = {
    deleted_alerts = {},
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
    {dictionary="gui", internal="delivering-to", localised={"ltnm-gui.delivering-to"}},
    {dictionary="gui", internal="fetching-from", localised={"ltnm-gui.fetching-from"}},
    {dictionary="gui", internal="loading-at", localised={"ltnm-gui.loading-at"}},
    {dictionary="gui", internal="parked-at-depot", localised={"ltnm-gui.parked-at-depot"}},
    {dictionary="gui", internal="returning-to-depot", localised={"ltnm-gui.returning-to-depot"}},
    {dictionary="gui", internal="unloading-at", localised={"ltnm-gui.unloading-at"}}
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
  global.translation_data = translation_data
end

return global_data