local alert_popup_gui = {}

local gui = require("__flib__.gui")
local mod_gui = require("mod-gui")

local main_gui = require("scripts.gui.main")

gui.add_handlers{
  alert_popup = {
    button = {
      on_gui_click = function(e)
        local player = game.get_player(e.player_index)
        local player_table = global.players[e.player_index]

        if
          e.button == defines.mouse_button_type.left
          and player_table.gui.main
          and player_table.gui.main.window.frame.valid
        then
          -- change tab and select correct alert
          main_gui.update(player, player_table, {active_tab="alerts", alerts=true})
          -- open in case it's closed
          main_gui.open(player, player_table, true)
        end
        -- destroy this button
        alert_popup_gui.destroy(player, player_table)
      end
    }
  }
}

function alert_popup_gui.create_or_update(player, player_table, alert_type)
  local gui_data = player_table.gui.alert_popup
  if not gui_data then
    gui_data = gui.build(mod_gui.get_frame_flow(player), {
      {type="button", style="red_button", style_mods={width=150, height=56}, tooltip={"ltnm-gui.alert-popup-tooltip"},
        mouse_button_filter={"left", "right"}, handlers="alert_popup.button", save_as="button", children={
          {type="flow", direction="vertical", elem_mods={ignored_by_interaction=true}, children={
            {type="label",
              style="ltnm_depot_button_bold_label",
              elem_mods={enabled=false},
              caption={"ltnm-gui.new-alert"}
            },
            {type="label", style="ltnm_depot_button_label", elem_mods={enabled=false}, save_as="label"}
          }}
        }
      }
    })
    player_table.gui.alert_popup = gui_data
  end
  gui_data.label.caption = {"ltnm-gui.alert-"..alert_type}
end

function alert_popup_gui.destroy(player, player_table)
  local gui_data = player_table.gui.alert_popup
  gui.update_filters("alert_popup", player.index, nil, "remove")
  gui_data.button.destroy()
  player_table.gui.alert_popup = nil
end

function alert_popup_gui.create_for_all(alert_type)
  local players = global.players
  for _, player in ipairs(game.connected_players) do
    local player_table = players[player.index]
    if player_table.flags.can_open_gui and player_table.settings.show_alert_popups then
      alert_popup_gui.create_or_update(player, players[player.index], alert_type)
    end
  end
end

return alert_popup_gui