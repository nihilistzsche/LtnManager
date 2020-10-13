local gui = require("__flib__.gui3")

local sort_checkbox = require("scripts.gui.main.components.common.sort-checkbox")

local component = gui.component()

function component.init()
  return {
    selected_sort = "depot",
    sort_depot = true,
    sort_train_id = false,
    sort_network_id = false,
    sort_route = true,
    sort_finished = true,
    sort_runtime = true,
    sort_shipment = true
  }
end

function component.update() end

function component.view(state)
  local gui_constants = state.constants.history
  local history_state = state.history

  return (
    {
      tab = {type = "tab", caption = {"ltnm-gui.history"}},
      content = (
        {type = "frame", style = "deep_frame_in_shallow_frame", direction = "vertical", children = {
          -- toolbar
          {type = "frame", style = "ltnm_table_toolbar_frame", children = {
            sort_checkbox(
              "history",
              "depot",
              "depot",
              nil,
              history_state,
              gui_constants
            )
          }},
          -- content
          {type = "scroll-pane", style = "ltnm_table_scroll_pane", children = {}}
        }}
      )
    }
  )
end

return component