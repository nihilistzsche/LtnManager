local gui = require("__flib__.gui3")

local constants = require("constants")

local component = gui.component()

function component.init()
  return {
    network_id = -1,
    query = "",
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

    state.search.query = string.lower(query)
  elseif msg.action == "update_network_id_query" then
    -- we don't need to sanitize this input, since it is a numeric textfield
    state.search.network_id = tonumber(e.element.text) or -1
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
        text = state.search.query,
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
        text = tostring(state.search.network_id),
        on_text_changed = {comp = "toolbar", action = "update_network_id_query"}
      },
      {type = "label", style = "subheader_caption_label", right_margin = 8, caption = "Surface:"},
      {type = "drop-down", items = {"(all)", "nauvis"}, selected_index = 1}
    }}
  )
end

return component