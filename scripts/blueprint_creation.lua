local Exports = {}

local special_dummy_tile = "sd-special-dummy-tile"

local function get_coord_data(x, y, name)
    return {
        key=tostring(x) .. "," .. tostring(y),
        position={x=x,y=y},
        name=name
    }
end

---@param player LuaPlayer
---@param cursor_stack LuaItemStack
---@param basis_tile tile_name?
---@param tile_layers tile_name[]
function Exports.create_blueprint(player, cursor_stack, basis_tile, tile_layers)
    local internal_tiles = {}
    local external_tiles = {}
    local old_blueprint_tiles = cursor_stack.get_blueprint_tiles()
    if not old_blueprint_tiles then
        player.create_local_flying_text({create_at_cursor=true, text={"sd.blueprint_must_include_tiles"}})
        return
    end

    if not basis_tile then
        internal_tiles = {
            key=special_dummy_tile,
            position={x=0,y=0},
            name=special_dummy_tile
        }
    else
        for _, tile in pairs(old_blueprint_tiles) do
            if tile.name == basis_tile then
                local tile_data = get_coord_data(tile.position.x, tile.position.y, tile.name)
                internal_tiles[tile_data.key] = tile_data
            end
        end
    end

    -- tile_layers = {
    --     "se-spaceship-floor",
    --     "rough-stone-path",
    --     "refined-hazard-concrete-left",
    --     "concrete",
    --     "refined-concrete",
    -- }

    for i, tile_layer in pairs(tile_layers) do
        for _, tile in pairs(internal_tiles) do
            if tile.name == tile_layers[i - 1] or (i == 1 and tile.name == basis_tile) then
                local adjs = {}
                local offsets = {-1, 0, 1}
                for _, v in pairs(offsets) do
                    for _, h in pairs(offsets) do
                        if not (v == 0 and h == 0) then
                            adjs[#adjs+1] = get_coord_data(tile.position.x + h, tile.position.y + v, tile_layer)
                        end
                    end
                end
                for _, adj in pairs(adjs) do
                    if not internal_tiles[adj.key] then
                        external_tiles[adj.key] = adj
                    end
                end
            end
        end
        for _, ext in pairs(external_tiles) do
            internal_tiles[ext.key] = ext
        end
    end

    global.script_inventory.clear()
    local blueprint = global.script_inventory.find_empty_stack()
    if not blueprint then return end
    blueprint.set_stack("sd_cursor_blueprint")
    local new_blueprint_tiles = {}
    for _, ext in pairs(external_tiles) do
        local entity_number = #new_blueprint_tiles+1
        new_blueprint_tiles[entity_number] = {
            entity_number=entity_number,
            name=ext.name,
            position={
                x=ext.position.x,
                y=ext.position.y,
            },
        }
    end
    blueprint.set_blueprint_tiles(new_blueprint_tiles)
    blueprint.blueprint_snap_to_grid = cursor_stack.blueprint_snap_to_grid
    blueprint.blueprint_position_relative_to_grid = cursor_stack.blueprint_position_relative_to_grid
    blueprint.blueprint_absolute_snapping = cursor_stack.blueprint_absolute_snapping
    player.clear_cursor()
    cursor_stack.set_stack(blueprint)
    global.script_inventory.clear()
end

return Exports