-- -------------------------------------------------------------------------------------------------------------------------------------------------------------
-- MIGRATIONS

-- dependencies
local event = require('lualib/event')

-- table of migration functions
local migrations = {}

-- returns true if v2 is newer than v1, false if otherwise
local function compare_versions(v1, v2)
  local v1_split = util.split(v1, '.')
  local v2_split = util.split(v2, '.')
  for i=1,#v1_split do
    if v1_split[i] < v2_split[i] then
      return true
    end
  end
  return false
end

-- handle migrations
event.on_configuration_changed(function(e)
  local changes = e.mod_changes[script.mod_name]
  if changes then
    local old = changes.old_version
    if old then
      -- version migrations
      local migrate = false
      for v,f in pairs(migrations) do
        if migrate or compare_versions(old, v) then
          migrate = true
          log('Applying migration: '..v)
          f(e)
        end
      end
    else
      return -- we just initialized, so don't do any migrations
    end
  end
  -- generic migrations
  log('Applying generic migrations')
  -- add migrations here...
end)