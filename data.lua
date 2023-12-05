local data_util = require("__flib__.data-util")

local cursor_blueprint = table.deepcopy(data.raw["blueprint"]["blueprint"])
cursor_blueprint.name = "sd_cursor_blueprint"
cursor_blueprint.order = "z_sd"
table.insert(cursor_blueprint.flags, "hidden")
table.insert(cursor_blueprint.flags, "only-in-cursor")

data:extend{
  cursor_blueprint,
  {
    type="shortcut",
    name="sd_decorate_spaceship",
    action="lua",
    icon=data_util.build_sprite(nil, {0, 0}, "__train-limit-linter__/graphics/shortcut.png", 32, 2), ---@todo add icon
    small_icon=data_util.build_sprite(nil, {0, 32}, "__train-limit-linter__/graphics/shortcut.png", 24, 2),
    diabled_icon=data_util.build_sprite(nil, {48, 0}, "__train-limit-linter__/graphics/shortcut.png", 32, 2),
    disabled_small_icon=data_util.build_sprite(nil, {36, 32}, "__train-limit-linter__/graphics/shortcut.png", 24, 2),
    -- icon=data_util.build_sprite(nil, {0, 0}, "__spaceship-decorator__/graphics/shortcut.png", 32, 2),
    -- small_icon=data_util.build_sprite(nil, {0, 32}, "__spaceship_decorator__/graphics/shortcut.png", 24, 2),
    -- diabled_icon=data_util.build_sprite(nil, {48, 0}, "__spaceship_decorator__/graphics/shortcut.png", 32, 2),
    -- disabled_small_icon=data_util.build_sprite(nil, {36, 32}, "__spaceship_decorator__/graphics/shortcut.png", 24, 2),
    toggleable=true,
    associated_control_input="sd_decorate_spaceship"
  }
}