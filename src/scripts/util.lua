local misc_util = require("__flib__.misc")

local util = {}

function util.material_button_tooltip(translations, name, count)
  return (
    "[img="..string.gsub(name, ",", "/")
    .."]  [font=default-bold]"
    ..translations.materials[name]
    .."[/font]"
    .."\n"
    .."[font=default-semibold]"
    ..translations.gui.count
    .."[/font] "
    ..misc_util.delineate_number(math.floor(count))
  )
end

return util