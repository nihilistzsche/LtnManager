data:extend{
  -- global
  {
    type = "int-setting",
    name = "ltnm-iterations-per-tick",
    setting_type = "runtime-global",
    minimum_value = 1,
    default_value = 10,
    order = "a"
  },
  -- player
  {
    type = "bool-setting",
    name = "ltnm-auto-refresh",
    setting_type = "runtime-per-user",
    default_value = false,
    order = "a",
  },
  {
    type = "bool-setting",
    name = "ltnm-keep-gui-open",
    setting_type = "runtime-per-user",
    default_value = false,
    hidden = true
  }
}