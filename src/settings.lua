data:extend{
  -- global
  {
    type = "int-setting",
    name = "ltnm-stations-per-tick",
    setting_type = "runtime-global",
    minimum_value = 1,
    default_value = 10,
    order = "a"
  },
  -- player
  {
    type = "bool-setting",
    name = "ltnm-show-alert-popups",
    setting_type = "runtime-per-user",
    default_value = true,
    order = "a"
  },
  {
    type = "bool-setting",
    name = "ltnm-auto-refresh",
    setting_type = "runtime-per-user",
    default_value = false,
    order = "b",
  },
  {
    type = "bool-setting",
    name = "ltnm-keep-gui-open",
    setting_type = "runtime-per-user",
    default_value = false,
    hidden = true
  }
}