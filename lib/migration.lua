-- Vendored from flib <= 0.16.x. The `flib_migration` module was removed in
-- flib 0.17.0, so this mod carries its own copy (matching how `lib.dictionary`
-- and `lib.gui` are vendored).

--- Mod migration and version comparison functions.
--- @class flib_migration
local flib_migration = {}

local string = string
local table = table

local version_pattern = "%d+"
local version_format = "%02d"

--- Normalize version strings for easy comparison.
--- @param version string
--- @param format string? default: `%02d`
--- @return string?
function flib_migration.format_version(version, format)
  if version then
    format = format or version_format
    local tbl = {}
    for v in string.gmatch(version, version_pattern) do
      tbl[#tbl + 1] = string.format(format, v)
    end
    if next(tbl) then
      return table.concat(tbl, ".")
    end
  end
  return nil
end

--- Check if current_version is newer than old_version.
--- @param old_version string
--- @param current_version string
--- @param format string? default: `%02d`
--- @return boolean?
function flib_migration.is_newer_version(old_version, current_version, format)
  local v1 = flib_migration.format_version(old_version, format)
  local v2 = flib_migration.format_version(current_version, format)
  if v1 and v2 then
    if v2 > v1 then
      return true
    end
    return false
  end
  return nil
end

--- Run migrations against the given version.
--- @param old_version string
--- @param migrations MigrationsTable
--- @param format? string default: `%02d`
--- @param ... any All additional arguments will be passed to each function within `migrations`.
function flib_migration.run(old_version, migrations, format, ...)
  local migrate = false
  for version, func in pairs(migrations) do
    if migrate or flib_migration.is_newer_version(old_version, version, format) then
      migrate = true
      func(...)
    end
  end
end

--- Determine if migrations need to be run for this mod, then run them if needed.
--- @param e ConfigurationChangedData
--- @param migrations? MigrationsTable
--- @param mod_name? string The mod to check against. Defaults to the current mod.
--- @param ... any All additional arguments will be passed to each function within `migrations`.
--- @return boolean run_generic_migrations
function flib_migration.on_config_changed(e, migrations, mod_name, ...)
  local changes = e.mod_changes[mod_name or script.mod_name]
  local old_version = changes and changes.old_version
  if old_version then
    if migrations then
      flib_migration.run(old_version, migrations, nil, ...)
    end
    return true
  end
  return false
end

--- Handle on_configuration_changed with the given generic and version-specific migrations. Will override any existing
--- on_configuration_changed event handler. Both arguments are optional.
--- @param version_migrations MigrationsTable?
--- @param generic_handler fun(e: ConfigurationChangedData)?
function flib_migration.handle_on_configuration_changed(version_migrations, generic_handler)
  script.on_configuration_changed(function(e)
    if flib_migration.on_config_changed(e, version_migrations) and generic_handler then
      generic_handler(e)
    end
  end)
end

return flib_migration

--- Migration code to run for specific mod version. A given function will run if the previous mod version is less
--- than the given version.
--- @alias MigrationsTable table<string, fun(...: any)>
