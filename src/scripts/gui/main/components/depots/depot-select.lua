local component = require("lib.gui-component")()

function component.update(player, player_table, state, refs, msg)
  if msg.update then
    local ltn_data = global.data

  end
end

function component.build()
  return (
    {
      type = "frame",
      style = "deep_frame_in_shallow_frame",
      width = 206,
      children = {
        {type = "scroll-pane", style = "ltnm_depot_select_scroll_pane", children = {

        }}
      }
    }
  )
end

return component