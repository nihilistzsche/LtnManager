local global_data = {}

local player_data = require("scripts.player-data")

function global_data.init()
  global.flags = {}
  global.players = {}
  global_data.build_translations()
  for i, player in pairs(game.players) do
    player_data.setup(player, i)
    player_data.refresh(player, global.players[i])
  end
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