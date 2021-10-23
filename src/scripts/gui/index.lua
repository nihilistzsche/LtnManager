local gui = require("__flib__.gui")

local actions = require("scripts.gui.actions")

-- Object methods

local Index = {}

Index.actions = actions

function Index:destroy()
  self.refs.window.destroy()
  self.player_table.guis.main = nil

  player.set_shortcut_toggled("ltnm-toggle-gui", false)
  player.set_shortcut_available("ltnm-toggle-gui", false)
end

function Index:open()
  self.refs.window.bring_to_front()
  self.refs.window.visible = true
  self.state.visible = true

  if not self.state.pinned then
    self.player.opened = self.refs.window
  end

  self.player.set_shortcut_toggled("ltnm-toggle-gui", true)
end

function Index:close()
  if self.state.pinning then return end

  self.refs.window.visible = false
  self.state.visible = false

  if self.player.opened == self.refs.window then
    self.player.opened = nil
  end

  self.player.set_shortcut_toggled("ltnm-toggle-gui", false)
end

function Index:toggle()
  if self.state.visible then
    Index.close(self)
  else
    Index.open(self)
  end
end

function Index:dispatch(msg, e)
  -- "Transform" the action based on criteria
  if msg.transform == "handle_refresh_click" then
    if e.shift then
      msg.action = "toggle_auto_refresh"
    else
      msg.refresh = true
    end
  end

  -- Dispatch the associated action
  if msg.action then
    local func = self.actions[msg.action]
    if func then
      func(self, msg, e)
    else
      log("Attempted to call action `"..msg.action.."` for which there is no handler yet.")
    end
  end
end

-- Constructor and utilities

local index = {}

local function frame_action_button(sprite, tooltip, ref, action)
  return {
    type = "sprite-button",
    style = "frame_action_button",
    sprite = sprite.."_white",
    hovered_sprite = sprite.."_black",
    clicked_sprite = sprite.."_black",
    mouse_button_filter = {"left"},
    tooltip = tooltip,
    ref = ref,
    actions = {on_click = action},
  }
end

function index.build(player, player_table)
  local refs = gui.build(player.gui.screen,{
    {
      type = "frame",
      direction = "vertical",
      visible = false,
      ref = {"window"},
      actions = {
        on_closed = {gui = "main", action = "close"},
      },
      {
        type = "flow",
        style = "flib_titlebar_flow",
        ref = {"titlebar", "flow"},
        {type = "label", style = "frame_title", caption = {"mod-name.LtnManager"}, ignored_by_interaction = true},
        {type = "empty-widget", style = "flib_titlebar_drag_handle", ignored_by_interaction = true},
        frame_action_button(
          "ltnm_pin",
          {"gui.ltnm-keep-open"},
          {"titlebar", "pin_button"},
          {gui = "main", action = "toggle_pinned"}
        ),
        frame_action_button(
          "ltnm_refresh",
          {"gui.ltnm-refresh-tooltip"},
          {"titlebar", "refresh_button"},
          {gui = "main", transform = "handle_refresh_click"}
        ),
        frame_action_button(
          "utility/close",
          {"gui.close-instruction"},
          nil,
          {gui = "main", action = "close"}
        ),
      },
      {type = "frame", style = "inside_deep_frame", direction = "vertical",
        {type = "frame", style = "subheader_frame", style_mods = {bottom_margin = 12},
          {type = "label", style = "subheader_caption_label", caption = {"gui.ltnm-search-label"}},
          {
            type = "textfield",
            style_mods = {left_margin = 8},
            clear_and_focus_on_right_click = true,
            ref = {"toolbar", "text_search_field"},
            actions = {
              on_text_changed = {gui = "main", action = "update_text_search_query"}
            }
          },
          {type = "empty-widget", style = "flib_horizontal_pusher"},
          {type = "label", style = "caption_label", caption = {"gui.ltnm-network-id-label"}},
          {
            type = "textfield",
            style_mods = {left_margin = 8, width = 120},
            numeric = true,
            allow_negative = true,
            clear_and_focus_on_right_click = true,
            text = "-1",
            ref = {"toolbar", "network_id_field"},
            actions = {
              on_text_changed = {gui = "main", action = "update_network_id_query"}
            }
          }
          -- TODO: maybe surface dropdown?
        },
        {type = "tabbed-pane", style = "ltnm_tabbed_pane"}
      }
    }
  })

  refs.titlebar.flow.drag_target = refs.window
  refs.window.force_auto_center()

  local Gui = {
    player = player,
    player_table = player_table,
    refs = refs,
    state = {
      closing = false,
      pinned = false,
      search_query = "",
    },
  }
  setmetatable(Gui, {__index = Index})

  player_table.guis.main = Gui

  player_table.flags.can_open_gui = true
  player.set_shortcut_available("ltnm-toggle-gui", true)
end

function index.get(player_index)
  local Gui = global.players[player_index].guis.main
  if Gui and Gui.refs.window.valid then
    return setmetatable(Gui, {__index = Index})
  end
end

return index
