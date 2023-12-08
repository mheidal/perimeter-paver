local data_util = require("__flib__.data-util")

local cursor_blueprint = table.deepcopy(data.raw["blueprint"]["blueprint"])
cursor_blueprint.name = "pp_cursor_blueprint"
cursor_blueprint.order = "z_sd"
table.insert(cursor_blueprint.flags, "hidden")
table.insert(cursor_blueprint.flags, "only-in-cursor")

data:extend{
  cursor_blueprint,
  {
    type="shortcut",
    name="pp_decorate",
    action="lua",
    icon=data_util.build_sprite(nil, {0, 0}, "__perimeter-paver__/graphics/star-dark-dashed-32.png", 32, 2), ---@todo add icon
    diabled_icon=data_util.build_sprite(nil, {48, 0}, "__perimeter-paver__/graphics/star-light-dashed-32.png", 32, 2),
    toggleable=true,
    associated_control_input="pp_decorate"
  }
}