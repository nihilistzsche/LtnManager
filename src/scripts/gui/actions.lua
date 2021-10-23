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

function actions.update_text_search_query(self)
  self.state.text_search_query = self.refs.toolbar.text_search_field.text
  self.schedule_refresh()
end

function actions.update_network_id_query(self)
  self.state.network_id_query = tonumber(self.refs.toolbar.network_id_field.text) or -1
  self.schedule_refresh()
end

return actions
