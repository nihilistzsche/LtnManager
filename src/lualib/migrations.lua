-- -------------------------------------------------------------------------------------------------------------------------------------------------------------
-- RAILUALIB MIGRATIONS MODULE
-- Migration handling for different versions.

-- Copyright (c) 2020 raiguard - https://github.com/raiguard
-- Permission is hereby granted, free of charge, to those obtaining this software or a portion thereof, to copy the contents of this software into their own
-- Factorio mod, and modify it to suit their needs. This is permissed under the condition that this notice and copyright information, as well as the link to
-- the documentation, are not omitted, and that any changes from the original are documented.

-- DOCUMENTATION: https://github.com/raiguard/Factorio-SmallMods/wiki/Migrations-Module-Documentation

-- -------------------------------------------------------------------------------------------------------------------------------------------------------------

-- object
local migrations = {}

-- returns true if v2 is newer than v1, false if otherwise
function migrations.compare_versions(v1, v2)
  local v1_split = util.split(v1, '.')
  local v2_split = util.split(v2, '.')
  for i=1,#v1_split do
    if v1_split[i] < v2_split[i] then
      return true
    end
  end
  return false
end

-- handle migrations generically
function migrations.generic(old, migrations_table, ...)
  local migrate = false
  for v,f in pairs(migrations_table) do
    if migrate or migrations.compare_versions(old, v) then
      migrate = true
      log('Applying migration: '..v)
      f()
    end
  end
end

-- handle version migrations in on_configuration_changed
function migrations.on_config_changed(e, migrations_table, ...)
  local changes = e.mod_changes[script.mod_name]
  if changes then
    local old = changes.old_version
    if old then
      migrations.generic(old, migrations_table, ...)
    else
      return false -- don't do generic migrations, because we just initialized
    end
  end
  return true
end

return migrations