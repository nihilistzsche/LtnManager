local component = require("lib.gui-component")()

function component.update(player, player_table, state, refs, handlers, msg, e)
  local selected_depot = state.depots.selected_depot
  local breakpoint
end

function component.build()
  return (
    {
      type = "frame",
      style = "deep_frame_in_shallow_frame",
      direction = "vertical",
      children = {
        {type = "frame", style = "ltnm_table_toolbar_frame", children = {
          {
            type = "checkbox",
            style = "ltnm_selected_sort_checkbox",
            caption = {"ltnm-gui.composition"},
            tooltip = {"ltnm-gui.composition-tooltip"},
            state = true,
            ref = {"depots", "trains_list", "sorters", "composition"}
          },
          {
            type = "checkbox",
            style = "ltnm_sort_checkbox",
            caption = {"ltnm-gui.train-status"},
            tooltip = {"ltnm-gui.train-status-tooltip"},
            state = true,
            ref = {"depots", "trains_list", "sorters", "status"}
          },
          {
            type = "checkbox",
            style = "ltnm_sort_checkbox",
            caption = {"ltnm-gui.contents"},
            tooltip = {"ltnm-gui.contents-tooltip"},
            state = true,
            ref = {"depots", "trains_list", "sorters", "contents"}
          },
          {type = "empty-widget", style = "flib_horizontal_pusher"}
        }},
        {type = "scroll-pane", style = "ltnm_table_scroll_pane", ref = {"depots", "trains_list", "scroll_pane"}}
      }
    }
  )
end

return component