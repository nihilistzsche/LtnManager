local train_util = require("__flib__.train")

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

-- TODO: Rate-limit these

function actions.update_text_search_query(self)
  self.state.search_query = self.refs.toolbar.text_search_field.text
  self:schedule_update()
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
  end

  train_util.open_gui(self.player.index, train_data.train)
end

function actions.open_station_gui(self, msg)
  local station_id = msg.station_id
  local station_data = self.state.ltn_data.stations[station_id]
  if not station_data or not station_data.entity.valid then
    util.error_flying_text(self.player, {"message.ltnm-error-station-is-invalid"})
  end

  self.player.opened = station_data.entity
end

return actions
