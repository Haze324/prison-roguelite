extends SceneTree

## Registers the canonical wall kit and transparent decoration set.
## Source 0 is the 48px/32px wall geometry; source 1 never owns wall pixels.
const STRUCTURE_ATLAS_PATH: String = "res://assets/generated/tilesets/industrial_prison/prison_wall_kit_48_v1.png"
const PROPS_ATLAS_PATH: String = "res://assets/generated/tilesets/industrial_prison/prison_modular_props_48_v1.png"
const OUTPUT_PATH: String = "res://resources/maps/prison_tileset_v1.tres"
const TILE_SIZE: Vector2i = Vector2i(48, 48)
const STRUCTURE_COLUMNS: int = 8
const STRUCTURE_ROWS: int = 6
const PROP_COLUMNS: int = 9
const PROP_ROWS: int = 9
const WALL_WIDTH: int = 32
const STRUCTURE_TILES: Array[Vector2i] = [
	Vector2i(0, 0), Vector2i(1, 0), Vector2i(2, 0), Vector2i(3, 0),
	Vector2i(0, 1), Vector2i(1, 1), Vector2i(2, 1), Vector2i(3, 1),
	Vector2i(4, 1), Vector2i(5, 1), Vector2i(6, 1), Vector2i(7, 1),
	Vector2i(0, 2), Vector2i(1, 2), Vector2i(2, 2), Vector2i(3, 2),
	Vector2i(4, 2), Vector2i(5, 2), Vector2i(6, 2), Vector2i(7, 2),
	Vector2i(0, 3), Vector2i(1, 3), Vector2i(2, 3), Vector2i(3, 3),
	Vector2i(0, 4), Vector2i(1, 4), Vector2i(2, 4), Vector2i(3, 4),
	Vector2i(4, 4), Vector2i(5, 4),
	Vector2i(0, 5), Vector2i(1, 5), Vector2i(2, 5), Vector2i(3, 5),
]

func _initialize() -> void:
	var structure_texture: Texture2D = load(STRUCTURE_ATLAS_PATH) as Texture2D
	var props_texture: Texture2D = load(PROPS_ATLAS_PATH) as Texture2D
	if structure_texture == null or props_texture == null:
		push_error("Could not load modular prison structure or prop atlas")
		quit(1)
		return
	var tile_set: TileSet = TileSet.new()
	tile_set.tile_size = TILE_SIZE
	tile_set.add_physics_layer()
	tile_set.set_physics_layer_collision_layer(0, 1)
	tile_set.set_physics_layer_collision_mask(0, 1)
	tile_set.add_occlusion_layer()
	tile_set.set_occlusion_layer_light_mask(0, 1)
	tile_set.add_custom_data_layer()
	tile_set.set_custom_data_layer_name(0, "tile_role")
	tile_set.set_custom_data_layer_type(0, TYPE_STRING)
	tile_set.add_custom_data_layer()
	tile_set.set_custom_data_layer_name(1, "connection_mask")
	tile_set.set_custom_data_layer_type(1, TYPE_INT)

	var structure: TileSetAtlasSource = TileSetAtlasSource.new()
	structure.texture = structure_texture
	structure.texture_region_size = TILE_SIZE
	for coords in STRUCTURE_TILES:
		structure.create_tile(coords)
	tile_set.add_source(structure, 0)
	for coords in STRUCTURE_TILES:
		_configure_structure_tile(structure, coords)

	var props: TileSetAtlasSource = TileSetAtlasSource.new()
	props.texture = props_texture
	props.texture_region_size = TILE_SIZE
	for y in range(PROP_ROWS):
		for x in range(PROP_COLUMNS):
			props.create_tile(Vector2i(x, y))
	tile_set.add_source(props, 1)
	for y in range(PROP_ROWS):
		for x in range(PROP_COLUMNS):
			var data: TileData = props.get_tile_data(Vector2i(x, y), 0)
			if data != null:
				data.set_custom_data("tile_role", "wall_prop_overlay")

	var error: Error = ResourceSaver.save(tile_set, OUTPUT_PATH)
	if error != OK:
		push_error("Could not save modular prison TileSet: " + str(error))
		quit(1)
		return
	print("PRISON TILESET BUILT: wall_kit=34 props=81 wall_width=32")
	quit(0)

func _configure_structure_tile(atlas: TileSetAtlasSource, coords: Vector2i) -> void:
	var data: TileData = atlas.get_tile_data(coords, 0)
	if data == null:
		return
	data.set_custom_data("tile_role", _tile_role(coords))
	data.set_custom_data("connection_mask", _connection_mask(coords))
	if not _is_solid_structure(coords):
		return
	var sides: Array[int] = _active_sides(_connection_mask(coords))
	data.set_collision_polygons_count(0, sides.size())
	data.set_occluder_polygons_count(0, sides.size())
	for index in range(sides.size()):
		var polygon: PackedVector2Array = _side_polygon(sides[index])
		data.set_collision_polygon_points(0, index, polygon)
		var occluder: OccluderPolygon2D = OccluderPolygon2D.new()
		occluder.polygon = polygon
		data.set_occluder_polygon(0, index, occluder)

func _is_solid_structure(coords: Vector2i) -> bool:
	return coords.y >= 1 and coords != Vector2i(5, 4)

func _active_sides(mask: int) -> Array[int]:
	var sides: Array[int] = []
	for side in [1, 2, 4, 8]:
		if mask & side:
			sides.append(side)
	return sides

func _side_polygon(side: int) -> PackedVector2Array:
	var half: float = float(TILE_SIZE.x) * 0.5
	var inner: float = half - float(WALL_WIDTH)
	match side:
		1: # N: upper wall face
			return PackedVector2Array([
				Vector2(-half, -half), Vector2(half, -half),
				Vector2(half, inner), Vector2(-half, inner),
			])
		2: # E: right wall face
			return PackedVector2Array([
				Vector2(inner, -half), Vector2(half, -half),
				Vector2(half, half), Vector2(inner, half),
			])
		4: # S: lower wall face
			return PackedVector2Array([
				Vector2(-half, inner), Vector2(half, inner),
				Vector2(half, half), Vector2(-half, half),
			])
		8: # W: left wall face
			return PackedVector2Array([
				Vector2(-half, -half), Vector2(inner, -half),
				Vector2(inner, half), Vector2(-half, half),
			])
	return PackedVector2Array()

func _tile_role(coords: Vector2i) -> String:
	if coords == Vector2i(5, 4):
		return "door_frame"
	if coords.y == 0:
		return "floor"
	if coords.y == 1:
		return "wall_horizontal_top" if coords.x < 4 else "wall_horizontal_bottom"
	if coords.y == 2:
		return "wall_vertical_left" if coords.x < 4 else "wall_vertical_right"
	if coords.y == 3:
		return "wall_corner"
	if coords.y == 4 and coords.x < 4:
		return "wall_t_junction"
	if coords == Vector2i(4, 4):
		return "wall_cross_junction"
	return "wall_cap"

func _connection_mask(coords: Vector2i) -> int:
	if coords.y == 0:
		return 0
	if coords.y == 1:
		return 1 if coords.x < 4 else 4
	if coords.y == 2:
		return 8 if coords.x < 4 else 2
	if coords.y == 3:
		return [9, 3, 6, 12][coords.x]
	if coords.y == 4 and coords.x < 4:
		return [11, 14, 7, 13][coords.x]
	if coords == Vector2i(4, 4):
		return 15
	if coords == Vector2i(5, 4):
		return 1
	return [1, 2, 4, 8][coords.x]
