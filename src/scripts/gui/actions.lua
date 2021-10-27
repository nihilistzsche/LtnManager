local train_util = require("__flib__.train")
local on_tick_n = require("__flib__.on-tick-n")

local util = require("scripts.util")

local actions = {}

local function toggle_fab(elem, sprite, state)
  if state then
    elem.style = "flib_selected_frame_action_button"
    elem.sprite = sprite.."_black"
  else
    elem.style = "frame_action_button"
    elem.sprite = sprite.."_white"
  end
end

function actions.close(self)
  self:close()
end

function actions.recenter(self)
  self.refs.window.force_auto_center()
end

function actions.toggle_auto_refresh(self)
  self.state.auto_refresh = not self.state.auto_refresh
  toggle_fab(self.refs.titlebar.refresh_button, "ltnm_refresh", self.state.auto_refresh)
end

function actions.toggle_pinned(self)
  self.state.pinned = not self.state.pinned
  toggle_fab(self.refs.titlebar.pin_button, "ltnm_pin", self.state.pinned)

  if self.state.pinned then
    self.state.pinning = true
    self.player.opened = nil
    self.state.pinning = false
  else
    self.player.opened = self.refs.window
    self.refs.window.force_auto_center()
  end
end

function actions.update_text_search_query(self, _, e)
  local text = e.element.text

  -- TODO: Sanitization and other stuffs
  self.state.search_query = text

  if self.state.search_job then
    on_tick_n.remove(self.state.search_job)
  end

  if #text == 0 then
    self:schedule_update()
  else
    self.state.search_job = on_tick_n.add(
      game.tick + 30,
      {gui = "main", action = "update", player_index = self.player.index}
    )
  end
end

function actions.update_network_id_query(self)
  self.state.network_id = tonumber(self.refs.toolbar.network_id_field.text) or -1
  self:schedule_update()
end

function actions.open_train_gui(self, msg)
  local train_id = msg.train_id
  local train_data = self.state.ltn_data.trains[train_id]

  if not train_data or not train_data.train.valid then
    util.error_flying_text(self.player, {"message.ltnm-error-train-is-invalid"})
    return
  end

  train_util.open_gui(self.player.index, train_data.train)
end

function actions.open_station_gui(self, msg)
  local station_id = msg.station_id
  local station_data = self.state.ltn_data.stations[station_id]

  if not station_data or not station_data.entity.valid then
    util.error_flying_text(self.player, {"message.ltnm-error-station-is-invalid"})
    return
  end

  self.player.opened = station_data.entity
end

function actions.toggle_sort(self, msg, e)
  local tab = msg.tab
  local column = msg.column

  local sorts = self.state.sorts[tab]
  local active_column = sorts._active
  if active_column == column then
    sorts[column] = e.element.state
  else
    sorts._active = column
    e.element.state = sorts[column]

    local old_checkbox = self.refs[tab].toolbar[active_column.."_checkbox"]
    old_checkbox.style = "ltnm_sort_checkbox"
    old_checkbox.style.width = self.widths[tab][active_column]
    e.element.style = "ltnm_selected_sort_checkbox"
    e.element.style.width = self.widths[tab][column]
  end

  self:schedule_update()
end

function actions.update(self)
  self:schedule_update()
end

function actions.change_tab(self, msg)
  self.state.active_tab = msg.tab
  self:schedule_update()
end

function actions.change_surface(self, _, e)
  local selected_index = e.element.selected_index
  local selected_surface_index = self.state.ltn_data.surfaces.selected_to_index[selected_index]
  if selected_surface_index then
    self.state.surface = selected_surface_index
    self:schedule_update()
  end
end

function actions.delete_alert(self, msg)
  global.active_data.alerts_to_delete[msg.alert_id] = true
  self:schedule_update()
end

return actions
