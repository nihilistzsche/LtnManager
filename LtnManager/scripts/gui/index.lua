local gui = require("__flib__.gui")
local misc = require("__flib__.misc")
local queue = require("lib.queue")
local table = require("__flib__.table")

local constants = require("constants")

local actions = require("actions")
local templates = require("templates")

local trains_tab = require("trains")
local depots_tab = require("depots")
local stations_tab = require("stations")
local inventory_tab = require("inventory")
local history_tab = require("history")
local alerts_tab = require("alerts")

-- Object methods

local Index = {}

Index.actions = actions

function Index:destroy()
    self.refs.window.destroy()
    self.player_table.guis.main = nil

    self.player.set_shortcut_toggled("ltnm-toggle-gui", false)
    self.player.set_shortcut_available("ltnm-toggle-gui", false)
end

function Index:open()
    self.state.ltn_data = global.data
    self:update() -- TODO: Do we want to do this every time?

    self.refs.window.bring_to_front()
    self.refs.window.visible = true
    self.state.visible = true

    if not self.state.pinned then self.player.opened = self.refs.window end

    self.player.set_shortcut_toggled("ltnm-toggle-gui", true)
end

function Index:close()
    if self.state.pinning then return end

    self.refs.window.visible = false
    self.state.visible = false

    if self.player.opened == self.refs.window then self.player.opened = nil end

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
            self.state.ltn_data = global.data
            self.do_update = true
        end
    elseif msg.transform == "handle_titlebar_click" then
        if e.button == defines.mouse_button_type.middle then msg.action = "recenter" end
    end

    -- Dispatch the associated action
    if msg.action then
        local func = self.actions[msg.action]
        if func then
            func(self, msg, e)
        else
            log("Attempted to call action `" .. msg.action .. "` for which there is no handler yet.")
        end
    end

    -- Update if necessary
    if self.do_update then
        self:update()
        self.do_update = false
    end
end

function Index:schedule_update() self.do_update = true end

function Index:update()
    local state = self.state
    local refs = self.refs

    local ltn_data = self.state.ltn_data

    -- Dispatcher status
    refs.titlebar.dispatcher_status_label.visible = not settings.global["ltn-dispatcher-enabled"].value

    -- Surface dropdown
    local surface_dropdown = refs.toolbar.surface_dropdown
    surface_dropdown.items = ltn_data.surfaces.items
    -- Validate that the selected index still exist
    local selected_index = table.find(ltn_data.surfaces.selected_to_index, state.surface)
    -- If the surface was invalidated since last update, reset to all
    if not selected_index then
        selected_index = 1
        state.surface = -1
    end
    surface_dropdown.selected_index = selected_index

    refs.trains.tab.badge_text = misc.delineate_number(#ltn_data.sorted_trains.composition)
    refs.depots.tab.badge_text = misc.delineate_number(#ltn_data.sorted_depots.name)
    refs.stations.tab.badge_text = misc.delineate_number(#ltn_data.sorted_stations.name)
    refs.history.tab.badge_text = misc.delineate_number(queue.length(ltn_data.history))
    refs.alerts.tab.badge_text = misc.delineate_number(queue.length(ltn_data.alerts))

    if state.active_tab == "trains" then
        trains_tab.update(self)
    elseif state.active_tab == "depots" then
        depots_tab.update(self)
    elseif state.active_tab == "stations" then
        stations_tab.update(self)
    elseif state.active_tab == "inventory" then
        inventory_tab.update(self)
    elseif state.active_tab == "history" then
        history_tab.update(self)
    elseif state.active_tab == "alerts" then
        alerts_tab.update(self)
    end
end

-- Constructor and utilities

local index = {}

function index.build(player, player_table)
    local widths = constants.gui[player_table.language] or constants.gui["en"]

    local refs = gui.build(player.gui.screen, {
        {
            type = "frame",
            direction = "vertical",
            visible = false,
            ref = { "window" },
            actions = {
                on_closed = { gui = "main", action = "close" },
            },
            {
                type = "flow",
                style = "flib_titlebar_flow",
                ref = { "titlebar", "flow" },
                actions = {
                    on_click = { gui = "main", transform = "handle_titlebar_click" },
                },
                {
                    type = "label",
                    style = "frame_title",
                    caption = { "mod-name.LtnManager" },
                    ignored_by_interaction = true,
                },
                { type = "empty-widget", style = "flib_titlebar_drag_handle", ignored_by_interaction = true },
                {
                    type = "label",
                    style = "bold_label",
                    style_mods = { font_color = constants.colors.red.tbl, left_margin = -4, top_margin = 1 },
                    caption = { "gui.ltnm-dispatcher-disabled" },
                    tooltip = { "gui.ltnm-dispatcher-disabled-description" },
                    ref = { "titlebar", "dispatcher_status_label" },
                    visible = false,
                },
                templates.frame_action_button(
                    "ltnm_pin",
                    { "gui.ltnm-keep-open" },
                    { "titlebar", "pin_button" },
                    { gui = "main", action = "toggle_pinned" }
                ),
                templates.frame_action_button(
                    "ltnm_refresh",
                    { "gui.ltnm-refresh-tooltip" },
                    { "titlebar", "refresh_button" },
                    { gui = "main", transform = "handle_refresh_click" }
                ),
                templates.frame_action_button(
                    "utility/close",
                    { "gui.close-instruction" },
                    nil,
                    { gui = "main", action = "close" }
                ),
            },
            {
                type = "frame",
                style = "inside_deep_frame",
                direction = "vertical",
                {
                    type = "frame",
                    style = "ltnm_main_toolbar_frame",
                    { type = "label", style = "subheader_caption_label", caption = { "gui.ltnm-search-label" } },
                    {
                        type = "textfield",
                        clear_and_focus_on_right_click = true,
                        ref = { "toolbar", "text_search_field" },
                        actions = {
                            on_text_changed = { gui = "main", action = "update_text_search_query" },
                        },
                    },
                    { type = "empty-widget", style = "flib_horizontal_pusher" },
                    { type = "label", style = "caption_label", caption = { "gui.ltnm-network-id-label" } },
                    {
                        type = "textfield",
                        style_mods = { width = 120 },
                        numeric = true,
                        allow_negative = true,
                        clear_and_focus_on_right_click = true,
                        text = "-1",
                        ref = { "toolbar", "network_id_field" },
                        actions = {
                            on_text_changed = { gui = "main", action = "update_network_id_query" },
                        },
                    },
                    { type = "label", style = "caption_label", caption = { "gui.ltnm-surface-label" } },
                    {
                        type = "drop-down",
                        ref = { "toolbar", "surface_dropdown" },
                        actions = {
                            on_selection_state_changed = { gui = "main", action = "change_surface" },
                        },
                    },
                },
                {
                    type = "tabbed-pane",
                    style = "ltnm_tabbed_pane",
                    trains_tab.build(widths),
                    depots_tab.build(widths),
                    stations_tab.build(widths),
                    inventory_tab.build(),
                    history_tab.build(widths),
                    alerts_tab.build(widths),
                },
            },
        },
    })

    refs.titlebar.flow.drag_target = refs.window
    refs.window.force_auto_center()

    local Gui = {
        player = player,
        player_table = player_table,
        refs = refs,
        state = {
            active_tab = "trains",
            closing = false,
            do_update = false,
            ltn_data = global.data,
            network_id = -1,
            sorts = {
                trains = {
                    _active = "train_id",
                    train_id = false,
                    status = false,
                    composition = false,
                    depot = false,
                    shipment = false,
                },
                depots = {
                    _active = "name",
                    name = false,
                    network_id = false,
                    status = false,
                    trains = false,
                },
                stations = {
                    _active = "name",
                    name = false,
                    status = false,
                    network_id = false,
                    provided_requested = false,
                    shipments = false,
                    control_signals = false,
                },
                history = {
                    _active = "runtime",
                    train_id = false,
                    route = false,
                    depot = false,
                    network_id = false,
                    runtime = false,
                    finished = true,
                    shipment = false,
                },
                alerts = {
                    _active = "time",
                    time = true,
                    train_id = false,
                    route = false,
                    network_id = false,
                    type = false,
                    contents = false,
                },
            },
            surface = -1,
            pinned = false,
            search_query = "",
            visible = false,
        },
        widths = widths,
    }

    index.load(Gui)

    player_table.guis.main = Gui

    player_table.flags.can_open_gui = true
    player.set_shortcut_available("ltnm-toggle-gui", true)
end

function index.load(Gui) setmetatable(Gui, { __index = Index }) end

function index.get(player_index)
    local Gui = global.players[player_index].guis.main
    if Gui and Gui.refs.window.valid then return setmetatable(Gui, { __index = Index }) end
end

return index
