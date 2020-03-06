-- -------------------------------------------------------------------------------------------------------------------------------------------------------------
-- SETTINGS

data:extend{
  -- global
  {
    type = 'int-setting',
    name = 'ltnm-stations-per-tick',
    setting_type = 'runtime-global',
    minimum_value = 1,
    default_value = 10,
    order = 'a'
  },
  -- player
  {
    type = 'bool-setting',
    name = 'ltnm-show-mod-gui-button',
    setting_type = 'runtime-per-user',
    default_value = false,
    order = 'a'
  }
}