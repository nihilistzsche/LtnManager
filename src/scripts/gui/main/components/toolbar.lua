local constants = require("constants")

local component = {}

function component.get_default_state()
  return {
    network_id = -1,
    query = "",
    surface = -1
  }
end

function component.update(msg, e)
  if msg.action == "update_search_query" then
    local _, _, state = util.get_updater_properties(e.player_index)

    local query = e.element.text

    -- input sanitization
    for pattern, replacement in pairs(constants.input_sanitizers) do
      query = string.gsub(query, pattern, replacement)
    end

    state.search.query = string.lower(query)

    gui.update("main", {tab = state.base.active_tab, update = true}, {player_index = e.player_index})
  elseif msg.action == "update_network_id_query" then
    local _, _, state = util.get_updater_properties(e.player_index)

    -- we don't need to sanitize this input, since it is a numeric textfield
    local query = tonumber(e.element.text) or -1

    state.search.network_id = query

    gui.update("main", {tab = state.base.active_tab, update = true}, {player_index = e.player_index})
  end
end

function component.build()
  return (
    {type = "frame", style = "subheader_frame", bottom_margin = 12, children = {
      -- TODO add tooltips
      {type = "label", style = "subheader_caption_label", right_margin = 8, caption = "Search:"},
      {
        type = "textfield",
        lose_focus_on_confirm = true,
        clear_and_focus_on_right_click = true,
        on_text_changed = {tab = "base", comp = "toolbar", action = "update_search_query"}
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
        text = "-1",
        on_text_changed = {tab = "base", comp = "toolbar", action = "update_network_id_query"}
      },
      {type = "label", style = "subheader_caption_label", right_margin = 8, caption = "Surface:"},
      {type = "drop-down", items = {"(all)", "nauvis"}, selected_index = 1}
    }}
  )
end

return component