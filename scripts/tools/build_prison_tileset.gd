extends SceneTree

## Registers the generated modular environment set.
## Source 0 is opaque structure; source 1 is transparent decoration and never owns wall pixels.
const STRUCTURE_ATLAS_PATH: String = "res://assets/generated/tilesets/industrial_prison/prison_modular_structure_48_v4.png"
const PROPS_ATLAS_PATH: String = "res://assets/generated/tilesets/industrial_prison/prison_modular_props_48_v1.png"
const OUTPUT_PATH: String = "res://resources/maps/prison_tileset_v1.tres"
const TILE_SIZE: Vector2i = Vector2i(48, 48)
const STRUCTURE_COLUMNS: int = 16
const STRUCTURE_ROWS: int = 8
const PROP_COLUMNS: int = 8
const PROP_ROWS: int = 8

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

	var structure: TileSetAtlasSource = TileSetAtlasSource.new()
	structure.texture = structure_texture
	structure.texture_region_size = TILE_SIZE
	for y in range(STRUCTURE_ROWS):
		for x in range(STRUCTURE_COLUMNS):
			structure.create_tile(Vector2i(x, y))
	tile_set.add_source(structure, 0)
	for y in range(STRUCTURE_ROWS):
		for x in range(STRUCTURE_COLUMNS):
			_configure_structure_tile(structure, Vector2i(x, y))

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
	print("MODULAR PRISON TILESET BUILT: structure=128 props=64")
	quit(0)

func _configure_structure_tile(atlas: TileSetAtlasSource, coords: Vector2i) -> void:
	var data: TileData = atlas.get_tile_data(coords, 0)
	if data == null:
		return
	data.set_custom_data("tile_role", _tile_role(coords))
	if not _is_solid_structure(coords):
		return
	var half: float = float(TILE_SIZE.x) * 0.5
	var polygon: PackedVector2Array = PackedVector2Array([
		Vector2(-half, -half), Vector2(half, -half),
		Vector2(half, half), Vector2(-half, half),
	])
	data.set_collision_polygons_count(0, 1)
	data.set_collision_polygon_points(0, 0, polygon)
	var occluder: OccluderPolygon2D = OccluderPolygon2D.new()
	occluder.polygon = polygon
	data.set_occluder_polygons_count(0, 1)
	data.set_occluder_polygon(0, 0, occluder)

func _is_solid_structure(coords: Vector2i) -> bool:
	return coords.y >= 1 and coords.y <= 5

func _tile_role(coords: Vector2i) -> String:
	if coords == Vector2i(4, 1):
		return "door_frame"
	if coords.y == 0:
		return "floor"
	if coords.y == 1:
		return "wall_horizontal"
	if coords.y == 2:
		return "wall_vertical"
	if coords.y == 5 and coords.x < 8:
		return "wall_corner"
	return "wall_structure"
