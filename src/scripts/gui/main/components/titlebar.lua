local gui = require("__flib__.gui-new")

local component = require("lib.gui-component")()

function component.update(player, state, refs, action, e)
  if action == "handle_refresh_click" then
    if e.shift then
      -- toggle auto refresh
      local auto_refresh = state.base.auto_refresh
      local refresh_button = refs.base.titlebar.refresh_button

      if auto_refresh then
        refresh_button.style = "frame_action_button"
        refresh_button.sprite = "ltnm_refresh_white"
        state.base.auto_refresh = false
      else
        refresh_button.style = "flib_selected_frame_action_button"
        refresh_button.sprite = "ltnm_refresh_black"
        state.base.auto_refresh = true
      end
    else
      -- refresh now
      gui.updaters.main({tab = state.base.active_tab, update = true}, {player_index = e.player_index})
    end
  elseif action == "toggle_pinned" then
    local pinned = state.base.pinned
    local pin_button = refs.base.titlebar.pin_button

    if pinned then
      pin_button.style = "frame_action_button"
      pin_button.sprite = "ltnm_pin_white"
      state.base.pinned = false

      player.opened = refs.base.window
      refs.base.window.force_auto_center()
    else
      pin_button.style = "flib_selected_frame_action_button"
      pin_button.sprite = "ltnm_pin_black"
      state.base.pinned = true

      -- a `pinning` flag is needed so the GUI doesn't close when we pin it
      state.base.pinning = true
      player.opened = nil
      state.base.pinning = false
    end
  end
end

local function frame_action_button(sprite, tooltip, on_click, ref)
  return {
    type = "sprite-button",
    style = "frame_action_button",
    sprite = sprite.."_white",
    hovered_sprite = sprite.."_black",
    clicked_sprite = sprite.."_black",
    tooltip = tooltip,
    on_click = on_click,
    ref = ref
  }
end

function component.build()
  return (
    {type = "flow", ref = {"base", "titlebar", "flow"}, children = {
      {type = "label", style = "frame_title", caption = {"mod-name.LtnManager"}, ignored_by_interaction = true},
      {type = "empty-widget", style = "flib_titlebar_drag_handle", ignored_by_interaction = true},
      frame_action_button(
        "ltnm_pin",
        {"ltnm-gui.keep-open"},
        {tab = "base", comp = "titlebar", action = "toggle_pinned"},
        {"base", "titlebar", "pin_button"}
      ),
      frame_action_button(
        "ltnm_refresh",
        {"ltnm-gui.refresh"},
        {tab = "base", comp = "titlebar", action = "handle_refresh_click"},
        {"base", "titlebar", "refresh_button"}
      ),
      frame_action_button("utility/close", nil, {tab = "base", comp = "base", action = "close"})
    }}
  )
end

return component