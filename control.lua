local gui = require("__flib__.gui-lite")
local blueprint_creation = require("scripts.blueprint_creation")

---@param event EventData.on_gui_checked_state_changed | EventData.on_gui_click | EventData.on_lua_shortcut | EventData.on_gui_closed | EventData.on_gui_opened
---@return LuaPlayer
local function get_player(event)
    local player = game.players[event.player_index]
    if not player then error("No such player") end
    return player
end

local constants = {
    actions = {
        close_gui="close_gui",
    },
    gui_element_names={
        main_frame="sd_main_frame",
    },
    settings_names={
        show_gui="sd-show-gui",
    },
}

local e = defines.events

local handlers = {}

---@param player LuaPlayer
function close_gui(player)
    local pg = global.players[player.index]
    local main_frame = pg.gui_elements[constants.gui_element_names.main_frame]
    if main_frame and main_frame.valid then
        main_frame.destroy()
    end
end

---@param player LuaPlayer
---@return boolean Whether the blueprint could be created
function create_blueprint(player)
    if not player.is_cursor_blueprint() then
        player.create_local_flying_text({create_at_cursor=true, text={"sd.must_have_blueprint_in_cursor"}})
        return false
    end
    local cursor_stack = player.cursor_stack
    if not cursor_stack or not cursor_stack.valid_for_read or not cursor_stack.can_set_stack() then return false end
    blueprint_creation.create_blueprint(player, cursor_stack)
    return true
end

---@param event EventData.on_gui_click
function handlers.handle_close_gui(event)
    local player = get_player(event)
    close_gui(player)
end

---@param event EventData.on_gui_click
function handlers.create_blueprint_and_close_gui(event)
    local player = get_player(event)
    local could_create_blueprint= create_blueprint(player)
    if could_create_blueprint then
        close_gui(player)
    end
end

---@param event EventData.on_gui_checked_state_changed
function handlers.toggle_show_gui(event)
    local player = get_player(event)
    local element = event.element
    if element and element.valid then
        local state = element.state
        local per_player_settings = settings.get_player_settings(player)
        per_player_settings[constants.settings_names.show_gui] = {value=state}
    end
end

---@param player LuaPlayer
local function open_gui(player)
    local main_frame = global.players[player.index].gui_elements[constants.gui_element_names.main_frame]
    if main_frame and main_frame.valid then return end

    local per_player_settings = settings.get_player_settings(player)

    local elements, main_frame = gui.add(player.gui.screen, {
        type="frame",
        name=constants.gui_element_names.main_frame,
        direction="vertical",
        style_mods={
            horizontally_stretchable=true,
            minimal_width=400,
        },
        children={
            {
                -- header
                type="flow",
                direction="horizontal",
                style="flib_titlebar_flow",
                children={
                    {
                        type="label",
                        caption="Tile Surrounder",
                        style="frame_title",
                    },
                    {
                        type="empty-widget",
                        style="flib_titlebar_drag_handle",
                        style_mods={
                            horizontally_stretchable=true,
                        },
                        drag_target=constants.gui_element_names.main_frame,
                    },
                    {
                        type="sprite-button",
                        handler={[e.on_gui_click] = handlers.handle_close_gui},
                        sprite="utility/close_white",
                        style="frame_action_button",
                    },
                }
            },
            {
                -- body
                type="frame",
                direction="vertical",
                style="deep_frame_in_shallow_frame",
                style_mods={
                    horizontally_stretchable=true,
                },
                children={
                    {
                        type="flow",
                        direction="vertical",
                        style_mods={
                            margin=12,
                        },
                        children={
                            {
                                type="checkbox",
                                state=per_player_settings[constants.settings_names.show_gui].value,
                                caption="Show this gui when creating blueprint [img=info]",
                                tooltip="Can be re-enabled in mod settings",
                                handler={[e.on_gui_checked_state_changed]=handlers.toggle_show_gui}
                            },
                        },
                    },
                }
            },
            {
                -- footer
                type="flow",
                direction="horizontal",
                style_mods={
                    top_padding=12,
                },
                children = {
                    {
                        type="empty-widget",
                        style="flib_dialog_footer_drag_handle",
                        drag_target=constants.gui_element_names.main_frame
                    },
                    {
                        type="button",
                        style="confirm_button",
                        caption="Create blueprint",
                        handler={[e.on_gui_click]=handlers.create_blueprint_and_close_gui}
                    }
                }
            }
        }
    })
    player.opened = main_frame
    main_frame.force_auto_center()
    global.players[player.index].gui_elements = elements
end

script.on_event(e.on_lua_shortcut, function(event)
    if event.prototype_name ==  "sd_decorate_spaceship" then
        local player = get_player(event)
        local per_player_settings = settings.get_player_settings(player)
        if per_player_settings[constants.settings_names.show_gui] then
            open_gui(player)
        else
            create_blueprint(player)
        end
    end
end)

script.on_event(e.on_gui_opened, function(event)
    local player = get_player(event)
    close_gui(player)
end)

script.on_event(e.on_gui_closed, function(event)
    local player = get_player(event)
    local element = event.element
    if element and element.name == constants.gui_element_names.main_frame then
        close_gui(player)
    end
end)

script.on_init(function ()
    global.script_inventory = game.create_inventory(10)
    global.players = {}
    for _, player in pairs(game.players) do
        global.players[player.index] = {
            gui_elements = {}
        }
    end
end)

gui.add_handlers(handlers)
gui.handle_events()