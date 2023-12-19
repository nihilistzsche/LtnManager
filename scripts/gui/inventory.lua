local misc = require("__flib__.misc")

local templates = require("templates")

local inventory_tab = {}

function inventory_tab.build()
  return {
    tab = {
      type = "tab",
      caption = { "gui.ltnm-inventory" },
      ref = { "inventory", "tab" },
      actions = {
        on_click = { gui = "main", action = "change_tab", tab = "inventory" },
      },
    },
    content = {
      type = "flow",
      style_mods = { horizontal_spacing = 12 },
      direction = "horizontal",
      ref = { "inventory", "content_frame" },
      templates.inventory_slot_table("provided", 12),
      templates.inventory_slot_table("in_transit", 8),
      templates.inventory_slot_table("requested", 6),
    },
  }
end

local function update_table(self, name, color)
  local translations = self.player_table.dictionaries.materials

  local state = self.state
  local refs = self.refs.inventory

  local search_query = state.search_query
  local search_network_id = state.network_id
  local search_surface = state.surface

  local ltn_inventory = state.ltn_data.inventory[name][search_surface]

  local i = 0

  local lua_table = table
  local table = refs[name].table
  local children = table.children

  local items = {}

  for name, count_by_network_id in pairs(ltn_inventory or {}) do
    if
      bit32.btest(count_by_network_id.combined_id, search_network_id)
      and string.find(string.lower(translations[name]), string.lower(search_query))
    then
      local running_count = 0
      for network_id, count in pairs(count_by_network_id) do
        if network_id ~= "combined_id" and bit32.btest(network_id, search_network_id) then
          running_count = running_count + count
        end
      end

      if running_count > 0 then
        lua_table.insert(items, {
          name = name,
          running_count = running_count
        })
      end
    end
  end

  local function by_descending_count(item1, item2)
    return item1.running_count > item2.running_count
  end
  lua_table.sort(items, by_descending_count)

  for _, item in ipairs(items) do
    i = i + 1
    local button = children[i]
    if not button then
      button = table.add({ type = "sprite-button", style = "flib_slot_button_" .. color, enabled = false })
    end
    button.sprite = string.gsub(item.name, ",", "/")
    button.number = item.running_count
    button.tooltip = "[img="
      .. string.gsub(item.name, ",", "/")
      .. "]  [font=default-semibold]"
      .. translations[item.name]
      .. "[/font]\n"
      .. misc.delineate_number(item.running_count)
  end

  for j = i + 1, #children do
    children[j].destroy()
  end
end

function inventory_tab.update(self)
  update_table(self, "provided", "green")
  update_table(self, "in_transit", "blue")
  update_table(self, "requested", "red")
end

return inventory_tab
