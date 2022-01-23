data:extend({
  {
    type = "int-setting",
    name = "ltnm-iterations-per-tick",
    setting_type = "runtime-global",
    minimum_value = 1,
    default_value = 10,
    order = "a",
  },
  {
    type = "int-setting",
    name = "ltnm-history-length",
    setting_type = "runtime-global",
    minimum_value = 10,
    maximum_value = 1000,
    default_value = 50,
    order = "a",
  },
})
