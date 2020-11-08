local gui = require("__flib__.gui-beta")

local constants = require("constants")

local util = require("scripts.util")

local component = {}

function component.build()
  return (
    {type = "frame", style = "subheader_frame", style_mods = {bottom_margin = 12}, children = {
      -- TODO add tooltips
      {
        type = "label",
        style = "subheader_caption_label",
        style_mods = {right_margin = 8},
        caption = {"ltnm-gui.search-label"}
      },
      {
        type = "textfield",
        lose_focus_on_confirm = true,
        clear_and_focus_on_right_click = true,
        handlers = {
          on_text_changed = "main_update_search_query"
        }
      },
      {type = "empty-widget", style = "flib_horizontal_pusher"},
      {
        type = "label",
        style = "subheader_caption_label",
        style_mods = {right_margin = 8},
        caption = {"ltnm-gui.network-id-label"}
      },
      {
        type = "textfield",
        style_mods = {width = 100},
        numeric = true,
        allow_negative = true,
        lose_focus_on_confirm = true,
        clear_and_focus_on_right_click = true,
        text = "-1",
        handlers = {
          on_text_changed = "main_update_network_id_query"
        }
      },
      {
        type = "label",
        style = "subheader_caption_label",
        style_mods = {right_margin = 8},
        caption = {"ltnm-gui.surface-label"}
      },
      {
        type = "drop-down",
        selected_index = 1,
        handlers = {
          on_selection_state_changed = "main_update_surface_query"
        },
        ref = {"base", "surface_dropdown"}
      }
    }}
  )
end

function component.setup(refs, ltn_data)
  refs.base.surface_dropdown.items = ltn_data.surfaces.items
  refs.base.surface_dropdown.selected_index = 1
end

function component.init()
  return {
    network_id = -1,
    query = "",
    surface = -1
  }
end

-- HANDLERS

local function update_search_query(e)
  local _, _, state, _ = util.get_gui_data(e.player_index)

  local query = e.element.text

  -- input sanitization
  for pattern, replacement in pairs(constants.input_sanitizers) do
    query = string.gsub(query, pattern, replacement)
  end

  state.search.query = string.lower(query)

  -- TODO update searchable content
end

local function update_network_id_query(e)
  local _, _, state, _ = util.get_gui_data(e.player_index)

  local text = e.element.text
  -- default to -1 if the nubmer can't be read
  state.search.network_id = tonumber(text) or -1

  -- TODO update searchable content
end

local function update_surface_query(e)
  local _, _, state, _ = util.get_gui_data(e.player_index)

  state.search.surface = state.ltn_data.surfaces.selected_to_index[e.element.selected_index] or -1

  -- TODO update searchable content
end

gui.add_handlers{
  main_update_search_query = update_search_query,
  main_update_network_id_query = update_network_id_query,
  main_update_surface_query = update_surface_query
}

return component