local misc = require("__flib__.misc")

local templates = require("templates")

local history_tab = {}

function history_tab.build(widths)
  return {
    tab = {
      type = "tab",
      caption = {"gui.ltnm-history"},
      ref = {"history", "tab"},
      actions = {
        on_click = {gui = "main", action = "change_tab", tab = "history"},
      },
    },
    content = {
      type = "frame",
      style = "ltnm_main_content_frame",
      {type = "frame", style = "ltnm_table_toolbar_frame",
        templates.sort_checkbox(
          widths,
          "history",
          "train_id",
          false
        ),
        templates.sort_checkbox(
          widths,
          "history",
          "route",
          false
        ),
        templates.sort_checkbox(
          widths,
          "history",
          "depot",
          true
        ),
        templates.sort_checkbox(
          widths,
          "history",
          "network_id",
          false
        ),
        templates.sort_checkbox(
          widths,
          "history",
          "runtime",
          false
        ),
        templates.sort_checkbox(
          widths,
          "history",
          "finished",
          false
        ),
        templates.sort_checkbox(
          widths,
          "history",
          "shipment",
          false
        ),
      },
    },
  }
end

function history_tab.update(self)

end

return history_tab
