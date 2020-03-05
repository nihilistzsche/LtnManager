-- -------------------------------------------------------------------------------------------------------------------------------------------------------------
-- MIGRATIONS

local migration = require('__RaiLuaLib__.lualib.migration')

-- table of migration functions
local migrations = {}

-- run the migrations
return function(e)
  if migration.on_config_changed(e, migrations) then
    -- add generic migrations here...
  end
end