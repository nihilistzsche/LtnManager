-- -------------------------------------------------------------------------------------------------------------------------------------------------------------
-- MIGRATIONS

local migrations = require('lualib/migrations')

-- table of migration functions
local migration_functions = {}

-- run the migrations
return function(e)
  if migrations.on_config_changed(e, migration_functions) then
    -- generic migrations
    log('Applying generic migrations')
    -- add migrations here...
  end
end