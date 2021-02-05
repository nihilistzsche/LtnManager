local gui = require("__flib__.gui-beta")

local constants = require("constants")

local component = gui.component()

function component.init()
  return {
    network_id = -1,
    network_id_text = "-1",
    query = "",
    query_text = "",
    surface = -1
  }
end

function component.update(state, msg, e)
  if msg.action == "update_search_query" then
    local query = e.element.text

    -- input sanitization
    for pattern, replacement in pairs(constants.input_sanitizers) do
      query = string.gsub(query, pattern, replacement)
    end

    state.search.query_text = e.element.text
    state.search.query = string.lower(query)
  elseif msg.action == "update_network_id_query" then
    local text = e.element.text
    -- default to -1 if the nubmer can't be read
    state.search.network_id = tonumber(text) or -1
    state.search.network_id_text = text
  elseif msg.action == "update_surface" then
    state.search.surface = state.ltn_data.surfaces.selected_to_index[e.element.selected_index] or -1
  end
end

function component.view(state)
  return (
    {type = "frame", style = "subheader_frame", bottom_margin = 12, children = {
      -- TODO add tooltips
      {type = "label", style = "subheader_caption_label", right_margin = 8, caption = "Search:"},
      {
        type = "textfield",
        lose_focus_on_confirm = true,
        clear_and_focus_on_right_click = true,
        text = state.search.query_text,
        on_text_changed = {comp = "toolbar", action = "update_search_query"}
      },
      {type = "empty-widget", style = "flib_horizontal_pusher"},
      {type = "label", style = "subheader_caption_label", right_margin = 8, caption = "Network ID:"},
      {
        type = "textfield",
        width = 100,
        numeric = true,
        allow_negative = true,
        lose_focus_on_confirm = true,
        clear_and_focus_on_right_click = true,
        text = state.search.network_id_text,
        on_text_changed = {comp = "toolbar", action = "update_network_id_query"}
      },
      {type = "label", style = "subheader_caption_label", right_margin = 8, caption = "Surface:"},
      {
        type = "drop-down",
        items = state.ltn_data.surfaces.items,
        selected_index = 1,
        on_selection_state_changed = {comp = "toolbar", action = "update_surface"}
      }
    }}
  )
end

return component
