-- -------------------------------------------------------------------------------------------------------------------------------------------------------------
-- HISTORY GUI
-- A tab of the main GUI

-- dependencies
local gui = require("__flib__.control.gui")
local util = require("scripts.util")

-- locals
local string_find = string.find
local string_gsub = string.gsub

-- object
local history_gui = {}

-- -----------------------------------------------------------------------------
-- GUI DATA

gui.add_handlers{
  history = {
    sort_checkbox = {
      on_gui_checked_state_changed = function(e)
        local _,_,clicked_type = string_find(e.element.name, "^ltnm_sort_history_(.-)$")
        local player_table = global.players[e.player_index]
        local gui_data = player_table.gui.main.history
        if gui_data.active_sort ~= clicked_type then
          -- update styles
          gui_data[gui_data.active_sort.."_sort_checkbox"].style = "ltnm_sort_checkbox_inactive"
          e.element.style = "ltnm_sort_checkbox_active"
          -- reset the checkbox value and switch active sort
          e.element.state = not e.element.state
          gui_data.active_sort = clicked_type
        else
          -- update the state in global
          gui_data["sort_"..clicked_type] = e.element.state
        end
        -- update GUI contents
        UPDATE_MAIN_GUI(game.get_player(e.player_index), player_table, {history=true})
      end
    },
    delete_button = {
      on_gui_click = function(e)
        -- remove from current data
        global.data.history = {}
        global.working_data.history = {}
        local sorted_history = global.data.sorted_history
        for key in pairs(sorted_history) do
          sorted_history[key] = {}
        end
        UPDATE_MAIN_GUI(game.get_player(e.player_index), global.players[e.player_index], {history=true})
      end
    }
  },
}

-- -----------------------------------------------------------------------------
-- FUNCTIONS

function history_gui.update(player, player_table, state_changes, gui_data, data, material_translations)
  -- HISTORY
  if state_changes.history then
    local history_table = gui_data.history.table
    history_table.clear()

    local active_sort = gui_data.history.active_sort
    local sort_value = gui_data.history["sort_"..active_sort]
    local sorted_history = data.sorted_history[active_sort]

    -- skip if the history is empty
    if #sorted_history > 0 then
      local history = data.history
      local start = sort_value and 1 or #sorted_history
      local finish = sort_value and #sorted_history or 1
      local delta = sort_value and 1 or -1

      for i=start,finish,delta do
        local entry = history[sorted_history[i]]
        local table_add = gui.build(history_table, {
          {type="label", style="bold_label", style_mods={width=140}, caption=entry.depot},
          {type="flow", style_mods={horizontally_stretchable=true, vertical_spacing=-1, top_padding=-2, bottom_padding=-1}, direction="vertical", children={
            {type="label", name="ltnm_view_station_"..entry.from_id, style="hoverable_bold_label", caption=entry.from,
              tooltip={"ltnm-gui.view-station-on-map"}},
            {type="flow", children={
              {type="label", style="caption_label", caption="->"},
              {type="label", name="ltnm_view_station_"..entry.to_id, style="hoverable_bold_label", caption=entry.to, tooltip={"ltnm-gui.view-station-on-map"}}
            }}
          }},
          {type="label", style_mods={right_margin=8, width=16, horizontal_align="right"}, caption=entry.network_id},
          {type="label", style_mods={right_margin=8, width=66, horizontal_align="right"}, caption=util.ticks_to_time(entry.runtime)},
          {type="label", style_mods={right_margin=8, width=64, horizontal_align="right"}, caption=util.ticks_to_time(entry.finished)},
          {type="frame", style="ltnm_dark_content_frame_in_light_frame", children={
            {type="scroll-pane", style="ltnm_train_slot_table_scroll_pane", children={
              {type="table", style="ltnm_small_slot_table", column_count=4, save_as="table"}
            }}
          }}
        }).table.add
        local mi = 0
        for name, count in pairs(entry.actual_shipment or entry.shipment) do
          mi = mi + 1
          table_add{type="sprite-button", name="ltnm_material_button_"..mi, style="ltnm_small_slot_button_dark_grey", sprite=string_gsub(name, ",", "/"),
            number=count, tooltip=(material_translations[name] or name).."\n"..util.comma_value(count)}
        end
      end
    end
  end
end

-- -----------------------------------------------------------------------------

history_gui.base_template = {type="frame", style="ltnm_light_content_frame", direction="vertical", mods={visible=false}, save_as="tabbed_pane.contents.history",
  children={
    -- toolbar
    {type="frame", style="ltnm_toolbar_frame", children={
      {type="checkbox", name="ltnm_sort_history_depot", style="ltnm_sort_checkbox_inactive", state=true, style_mods={width=140, left_margin=8},
        caption={"ltnm-gui.depot"}, handlers="history.sort_checkbox", save_as="history.depot_sort_checkbox"},
      {type="checkbox", name="ltnm_sort_history_route", style="ltnm_sort_checkbox_inactive", state=true, caption={"ltnm-gui.route"},
        handlers="history.sort_checkbox", save_as="history.route_sort_checkbox"},
      {template="pushers.horizontal"},
      {type="checkbox", name="ltnm_sort_history_network_id", style="ltnm_sort_checkbox_inactive", style_mods={right_margin=8}, state=true,
        caption={"ltnm-gui.id"}, tooltip={"ltnm-gui.history-network-id-tooltip"}, handlers="history.sort_checkbox", save_as="history.network_id_sort_checkbox"},
      {type="checkbox", name="ltnm_sort_history_runtime", style="ltnm_sort_checkbox_inactive", style_mods={right_margin=8}, state=true,
        caption={"ltnm-gui.runtime"}, handlers="history.sort_checkbox", save_as="history.runtime_sort_checkbox"},
      {type="checkbox", name="ltnm_sort_history_finished", style="ltnm_sort_checkbox_active", style_mods={right_margin=8}, state=false,
        caption={"ltnm-gui.finished"}, handlers="history.sort_checkbox", save_as="history.finished_sort_checkbox"},
      {type="label", style="caption_label", style_mods={width=124}, caption={"ltnm-gui.shipment"}},
      {type="sprite-button", style="red_icon_button", sprite="utility/trash", tooltip={"ltnm-gui.clear-history"},
        handlers="history.delete_button", save_as="history.delete_button"}
    }},
    -- listing
    {type="scroll-pane", style="ltnm_blank_scroll_pane", style_mods={horizontally_stretchable=true, vertically_stretchable=true},
      vertical_scroll_policy="always", save_as="history.pane", children={
        {type="table", style="ltnm_rows_table", style_mods={vertically_stretchable=true}, column_count=6, save_as="history.table"}
      }
    }
  }
}

return history_gui