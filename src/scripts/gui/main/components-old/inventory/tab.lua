local gui = require("__flib__.gui-beta")

local util = require("scripts.util")

local component = gui.component()

function component.update() end

local function slot_table(caption, materials, state, color, columns)
  local buttons = {}
  local button_style = "flib_slot_button_"..color

  if materials then
    local search_query = state.search.query
    local search_network_id = state.search.network_id

    local translations = state.translations
    local material_translations = translations.materials

    local i = 0

    for name, data in pairs(materials) do
      if
        bit32.btest(data.combined_id, search_network_id)
        and string.find(string.lower(material_translations[name]), search_query)
      then
        local running_count = 0
        for network_id, count in pairs(data) do
          if network_id ~= "combined_id" and bit32.btest(network_id, search_network_id) then
            running_count = running_count + count
          end
        end

        if running_count > 0 then
          i = i + 1
          buttons[i] = {
            type = "sprite-button",
            style = button_style,
            sprite = string.gsub(name, ",", "/"),
            number = running_count,
            tooltip = util.material_button_tooltip(translations, name, running_count),
            enabled = false
          }
        end
      end
    end
  end

  return (
    {type = "frame", style = "deep_frame_in_shallow_frame", direction = "vertical", children = {
      {type = "frame", style = "subheader_frame", height = 32, width = (40 * columns), children = {
        {type = "label", style = "subheader_caption_label", caption = {"ltnm-gui."..caption}},
      }},
      {
        type = "scroll-pane",
        style = "ltnm_slot_table_scroll_pane",
        width = (40 * columns),
        height = (40 * 17),
        children = {
          {type = "table", style = "slot_table", column_count = columns, children = buttons}
        }
      }
    }}
  )
end

function component.view(state)
  local inventory = state.ltn_data.inventory
  local surface_index = state.search.surface
  return (
    {
      tab = {type = "tab", caption = {"ltnm-gui.inventory"}},
      content = (
        {type = "flow", horizontal_spacing = 12, children = {
          slot_table("provided", inventory.provided[surface_index], state, "green", 13),
          slot_table("requested", inventory.requested[surface_index], state, "red", 7),
          slot_table("in-transit", inventory.in_transit[surface_index], state, "blue", 7)
        }}
      )
    }
  )
end

return component
