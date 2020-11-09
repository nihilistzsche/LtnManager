local gui = require("__flib__.gui-beta")

local constants = require("constants")

local util = require("scripts.util")

local root = require("scripts.gui.main.components.root")

local main_gui = {}

function main_gui.build(player, player_table)
  local widths = constants.gui[player_table.translations.gui.locale_identifier]
  -- build GUI
  local refs = gui.build(player.gui.screen, {root.build(widths)})
  local state = root.init(widths)
  root.setup(refs, state.ltn_data)

  player_table.gui.main = {
    refs = refs,
    state = state
  }

  -- set flag and shortcut state
  player_table.flags.can_open_gui = true
  player.set_shortcut_available("ltnm-toggle-gui", true)
end

function main_gui.destroy(player, player_table)
  -- destroy and remove GUI from player table
  player_table.gui.main.refs.window.destroy()
  player_table.gui.main = nil

  -- set flag and shortcut state
  player_table.flags.can_open_gui = false
  player.set_shortcut_available("ltnm-toggle-gui", false)
end

function main_gui.toggle(player_index, player_table)
  local gui_data = player_table.gui.main
  local action = gui_data.state.base.visible and "close" or "open"
  -- update LTN data and dynamic content before opening
  if action == "open" then
    main_gui.update_ltn_data(player_index)
  end
  root[action]{player_index = player_index}
end

-- update dynamic content
function main_gui.update(player_index)
  local player, player_table, state, refs = util.get_gui_data(player_index)
  root.update(player, player_table, state, refs)
end

-- update LTN data, then dynamic content
function main_gui.update_ltn_data(player_index)
  local player, player_table, state, refs = util.get_gui_data(player_index)
  state.ltn_data = global.data
  -- TODO update surface dropdown
  root.update(player, player_table, state, refs)
end

function main_gui.focus_search(gui_data)
  local textfield = gui_data.refs.base.search_query_textfield
  textfield.select_all()
  textfield.focus()
end

return main_gui