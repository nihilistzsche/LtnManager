local global_data = {}

function global_data.init()
  global_data.build_translations()
  global.flags = {
    iterating_ltn_data = false,
    updating_guis = false
  }
  global.players = {}
end

function global_data.build_translations()
  local translation_data = {
    gui = {
      -- train status
      {internal="delivering-to", localised={"ltnm-gui.delivering-to"}},
      {internal="fetching-from", localised={"ltnm-gui.fetching-from"}},
      {internal="loading-at", localised={"ltnm-gui.loading-at"}},
      {internal="parked-at-depot", localised={"ltnm-gui.parked-at-depot"}},
      {internal="returning-to-depot", localised={"ltnm-gui.returning-to-depot"}},
      {internal="unloading-at", localised={"ltnm-gui.unloading-at"}}
    },
    materials = {}
  }
  -- materials
  for _, type in ipairs{"fluid", "item"} do
    local prefix = type..","
    for name, prototype in pairs(game[type.."_prototypes"]) do
      translation_data.materials[#translation_data.materials+1] = {internal=prefix..name, localised=prototype.localised_name}
    end
  end
  global.translation_data = translation_data
end

return global_data