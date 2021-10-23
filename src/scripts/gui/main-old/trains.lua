local constants = require("constants")

local trains_tab = {}

function trains_tab.build()
  return {
    tab = {type = "tab", caption = {"gui.ltnm-trains"}, ref = {"trains", "tab"}},
    content = {type = "frame", style = "deep_frame_in_shallow_frame", direction = "vertical", children = {
      {type = "frame", style = "ltnm_table_toolbar_frame", children = {
        {type = "empty-widget", style_mods = {width = 94}},
        {
          type = "checkbox",
          style = "ltnm_sort_checkbox",
          caption = {"gui.ltnm-depot"},
          state = false,
          ref = {"trains", "toolbar", "depot_checkbox"},
          actions = {
            on_checked_state_changed = {gui = "main", action = "update_sort", sort = "depot"}
          }
        },
        {
          type = "checkbox",
          style = "ltnm_sort_checkbox",
          caption = {"gui.ltnm-composition"},
          state = false,
          ref = {"trains", "toolbar", "composition_checkbox"},
          actions = {
            on_checked_state_changed = {gui = "main", action = "update_sort", sort = "composition"}
          }
        },
        {
          type = "checkbox",
          style = "ltnm_sort_checkbox",
          caption = {"gui.ltnm-status"},
          state = false,
          ref = {"trains", "toolbar", "status_checkbox"},
          actions = {
            on_checked_state_changed = {gui = "main", action = "update_sort", sort = "status"}
          }
        },
        {
          type = "checkbox",
          style = "ltnm_sort_checkbox",
          caption = {"gui.ltnm-shipment"},
          state = false,
          ref = {"trains", "toolbar", "shipment_checkbox"},
          actions = {
            on_checked_state_changed = {gui = "main", action = "update_sort", sort = "shipment"}
          }
        },
        {type = "empty-widget", style = "flib_horizontal_pusher"}
      }},
      {
        type = "scroll-pane",
        style = "flib_naked_scroll_pane_no_padding",
        style_mods = {vertically_stretchable = true},
        children = {
          -- EXPERIMENTAL
          {type = "frame", style = "ltnm_table_row_frame", children = {
            {
              type = "frame",
              style = "deep_frame_in_shallow_frame",
              style_mods = {top_margin = 1, bottom_margin = 6, right_margin = 4},
              children = {
                {type = "minimap", style = "ltnm_train_minimap", position = {0, 0}, zoom = 1, children = {
                  {type = "button", style = "ltnm_train_minimap_button"}
                }}
              }
            },
            {type = "label", style = "ltnm_clickable_bold_label", caption = "Depot"},
            {type = "empty-widget", style = "flib_horizontal_pusher"}
          }}
        }
      }
    }}
  }
end

function trains_tab.init()
end

function trains_tab.refresh(refs, state)
end

return trains_tab
