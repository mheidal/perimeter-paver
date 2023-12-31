local gui = require("__flib__.gui-lite")
local blueprint_creation = require("scripts.blueprint_creation")

---@class PlayerGlobal
---@field gui_elements {[gui_element_name]: LuaGuiElement?}
---@field basis_tile tile_name?
---@field tile_layers tile_name[]

---@alias gui_element_name string
---@alias tile_name string

---@param event EventData.on_gui_checked_state_changed | EventData.on_gui_click | EventData.on_lua_shortcut | EventData.on_gui_closed | EventData.on_gui_opened | EventData.on_gui_elem_changed | EventData.on_gui_text_changed | EventData.CustomInputEvent | EventData.on_lua_shortcut
---@return LuaPlayer
local function get_player(event)
    local player = game.players[event.player_index]
    if not player then error("No such player") end
    return player
end

---@param player LuaPlayer
---@return PlayerGlobal
local function get_player_global(player)
    return global.players[player.index]
end

local constants = {
    actions = {
        close_gui="close_gui",
    },
    gui_element_names={
        main_frame="pp_main_frame",
        layer_table="pp_layer_table", -- this one might be duplicated, but unique within configurations? Not sure
        basis_tile_label="pp_basis_layer_tile",
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
        player.create_local_flying_text({create_at_cursor=true, text={"pp.must_have_blueprint_in_cursor"}})
        return false
    end
    local cursor_stack = player.cursor_stack
    if not cursor_stack or not cursor_stack.valid_for_read or not cursor_stack.can_set_stack() then return false end
    local pg = get_player_global(player)
    blueprint_creation.create_blueprint(player, cursor_stack, pg.basis_tile, pg.tile_layers)
    return true
end

---@param player LuaPlayer
function build_layer_table(player)
    local tile_prototypes = game.tile_prototypes
    local pg = get_player_global(player)
    local layer_table = pg.gui_elements[constants.gui_element_names.layer_table]
    if not layer_table or not layer_table.valid then return end
    layer_table.clear()
    for i, tile_layer in ipairs(pg.tile_layers) do
        gui.add(layer_table, {
            type="sprite-button",
            sprite="tile/" .. tile_layer,
            tooltip={"pp.tile_layer_tooltip", tile_prototypes[tile_layer].localised_name},
            tags={tile_layer_index=i, tile=tile_layer},
            handler={[e.on_gui_click]=handlers.click_tile_layer}
        })
    end
    for _=1,(8-(#pg.tile_layers % 8)) do
        gui.add(layer_table, {
            type="empty-widget",
            style_mods={
                size=40
            }
        })
    end
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

---@param event EventData.on_gui_elem_changed
function handlers.choose_basis_tile(event)
    local player = get_player(event)
    local pg = get_player_global(player)
    local element = event.element
    if not element or not element.valid then return end
    ---@type tile_name?
    local basis_tile = element.elem_value ---@diagnostic disable-line Creation of gui element ensures this is a tile or nil
    pg.basis_tile = basis_tile
    local tile_prototypes = game.tile_prototypes
    pg.gui_elements[constants.gui_element_names.basis_tile_label].caption = pg.basis_tile and tile_prototypes[pg.basis_tile].localised_name or {"pp.no_selected_basis"}
end

---@param event EventData.on_gui_elem_changed
function handlers.add_tile_layer(event)
    local player = get_player(event)
    local pg = get_player_global(player)
    local element = event.element
    if not element or not element.valid then return end
    ---@type tile_name?
    local tile = element.elem_value ---@diagnostic disable-line Creation of gui element ensures this is a tile or nil
    if not tile then return end

    pg.tile_layers[#pg.tile_layers + 1] = tile
    element.elem_value = nil
    build_layer_table(player)

end

---@param event EventData.on_gui_click
function handlers.click_tile_layer(event)
    local player = get_player(event)
    local pg = get_player_global(player)
    local element = event.element
    if not element or not element.valid then return end
    local left = event.button == defines.mouse_button_type.left
    local right = event.button == defines.mouse_button_type.right
    local ctrl = event.control
    local shift = event.shift

    local prev_index = element.tags.tile_layer_index
    if not prev_index or type(prev_index) ~= "number" then return end

    if right and ctrl and not shift then
        table.remove(pg.tile_layers, prev_index)
    else
        local tile = element.tags.tile
        local target_index
        if right and not ctrl and not shift then
            target_index = math.min(#pg.tile_layers, prev_index + 1)
        elseif right and not ctrl and shift then
            target_index = #pg.tile_layers
        elseif left and not ctrl and not shift then
            target_index = math.max(1, prev_index - 1)
        elseif left and not ctrl and shift then
            target_index = 1
        end
        if not target_index or target_index == prev_index then return end
        table.remove(pg.tile_layers, prev_index)
        table.insert(pg.tile_layers, target_index, tile)
    end

    build_layer_table(player)
end

---@param player LuaPlayer
local function open_gui(player)
    local pg = get_player_global(player)

    local tile_prototypes = game.tile_prototypes

    local existing_main_frame = global.players[player.index].gui_elements[constants.gui_element_names.main_frame]
    if existing_main_frame and existing_main_frame.valid then return end

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
                        caption={"pp.titlebar_caption"},
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
                style="inside_shallow_frame",
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
                                type="label",
                                caption={"pp.choose_basis_tile"},
                                tooltip={"pp.choose_basis_tile_tt"}
                            },
                            {
                                type="flow",
                                direction="horizontal",
                                style_mods={
                                    vertical_align="center",
                                },
                                children={
                                    {
                                        type="choose-elem-button",
                                        elem_type="tile",
                                        tile=pg.basis_tile,
                                        elem_filters={{filter="blueprintable",}},
                                        handler={[e.on_gui_elem_changed]=handlers.choose_basis_tile}
                                    },
                                    {
                                        type="label",
                                        name=constants.gui_element_names.basis_tile_label,
                                        caption=pg.basis_tile and tile_prototypes[pg.basis_tile].localised_name or {"pp.no_selected_basis"},
                                    },
                                }
                            },
                            {type="line"},
                            {
                                type="label",
                                caption={"pp.choose_surrounding_tiles"},
                            },
                            {
                                type="frame",
                                style="slot_button_deep_frame",
                                style_mods={
                                    top_margin=12,
                                    bottom_margin=12,
                                },
                                children={
                                    {
                                    type="table",
                                    column_count=8,
                                    name=constants.gui_element_names.layer_table,
                                    }
                                }
                            },
                            {
                                type="choose-elem-button",
                                elem_type="tile",
                                elem_filters={{filter="blueprintable",}},
                                handler={[e.on_gui_elem_changed]=handlers.add_tile_layer},
                            },
                            {type="line"},
                            {
                                type="checkbox",
                                state=per_player_settings[constants.settings_names.show_gui].value,
                                caption={"pp.show_gui_checkbox"},
                                tooltip={"pp.show_gui_checkbox_tt"},
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
                        caption={"pp.create_blueprint"},
                        handler={[e.on_gui_click]=handlers.create_blueprint_and_close_gui}
                    }
                }
            }
        }
    })
    player.opened = main_frame
    global.players[player.index].gui_elements = elements
    build_layer_table(player)
    main_frame.force_auto_center()
end

---@param event EventData.on_lua_shortcut | EventData.CustomInputEvent
local function handle_use_tool(event)
    local name = event.prototype_name or event.input_name
    if name == "pp_use_tool" then
        local player = get_player(event)
        local per_player_settings = settings.get_player_settings(player)
        if per_player_settings[constants.settings_names.show_gui].value then
            open_gui(player)
        else
            create_blueprint(player)
        end
    end
end

script.on_event(e.on_lua_shortcut, handle_use_tool)
script.on_event("pp_use_tool", handle_use_tool)

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

---@return PlayerGlobal
function get_new_player_global()
    return {
        gui_elements = {},
        basis_tile=nil,
        tile_layers={}
    }
end

script.on_init(function ()
    global.script_inventory = game.create_inventory(10)
    global.players = {}
    for _, player in pairs(game.players) do
        global.players[player.index] = get_new_player_global()
    end
end)

script.on_configuration_changed(function (config_changed_data)
    if config_changed_data.mod_changes["perimeter-paver"] then
        for _, player in pairs(game.players) do
            local old_global = global.players[player.index]
            local new_global = get_new_player_global()
            for key, value in pairs(old_global) do
                if type(value) == "table" then
                    for subkey, subvalue in pairs(value) do
                        if new_global[key] and new_global[key][subkey] ~= nil then
                            new_global[key][subkey] = subvalue
                        end
                    end
                else
                    if new_global[key] then
                        new_global[key] = value
                    end
                end
            end
            global.players[player.index] = new_global
            close_gui(player)
        end
    end
end)

gui.add_handlers(handlers)
gui.handle_events()