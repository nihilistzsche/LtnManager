local component = require("lib.gui-component")()

component.template = (
  {
    type = "frame",
    style = "deep_frame_in_shallow_frame",
    direction = "vertical",
    save_as_prefix = "trains_list.",
    children = {
      {type = "frame", style = "ltnm_table_toolbar_frame", children = {
        {
          type = "checkbox",
          style = "ltnm_active_sort_checkbox",
          caption = {"ltnm-gui.composition"},
          tooltip = {"ltnm-gui.composition-tooltip"},
          state = true
        },
        {
          type = "checkbox",
          style = "ltnm_sort_checkbox",
          caption = {"ltnm-gui.train-status"},
          tooltip = {"ltnm-gui.train-status-tooltip"},
          state = true
        },
        {
          type = "checkbox",
          style = "ltnm_sort_checkbox",
          caption = {"ltnm-gui.contents"},
          tooltip = {"ltnm-gui.contents-tooltip"},
          state = true
        },
        {type = "empty-widget", style = "flib_horizontal_pusher"}
      }},
      {type = "scroll-pane", style = "ltnm_table_scroll_pane", children = {
        {
          type = "frame",
          style = "ltnm_table_row_frame",
          children = {
            {type = "label", style = "bold_label", caption = "<L<CC>L>"},
            {type = "empty-widget", style = "flib_horizontal_pusher"},
            {type = "frame", style = "deep_frame_in_shallow_frame", children = {
              {type = "sprite-button", style = "ltnm_small_slot_button_default", sprite = "item/iron-ore"}
            }}
          }
        }
      }}
    }}
)

return component