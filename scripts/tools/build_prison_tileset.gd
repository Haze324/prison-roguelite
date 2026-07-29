extends SceneTree

## Builds a usable TileSet from the 7x8 atlas produced by slice_prison_contact_sheet.gd.
## It deliberately does not infer a grid from the contact sheet at build time.
const ATLAS_PATH: String = "res://assets/generated/tilesets/industrial_prison/prison_tileset_sliced_48_v6.png"
const OUTPUT_PATH: String = "res://resources/maps/prison_tileset_v1.tres"
const TILE_SIZE: Vector2i = Vector2i(48, 48)
const GRID_COLUMNS: int = 7
const GRID_ROWS: int = 8
const SOLID_TILES: Array[Vector2i] = [
	Vector2i(2, 0), Vector2i(0, 1), Vector2i(1, 1), Vector2i(2, 2),
]

func _initialize() -> void:
	var texture: Texture2D = load(ATLAS_PATH) as Texture2D
	if texture == null:
		push_error("Could not load sliced prison tile atlas: " + ATLAS_PATH)
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

	var atlas: TileSetAtlasSource = TileSetAtlasSource.new()
	atlas.texture = texture
	atlas.texture_region_size = TILE_SIZE
	for y in range(GRID_ROWS):
		for x in range(GRID_COLUMNS):
			atlas.create_tile(Vector2i(x, y))
	tile_set.add_source(atlas, 0)
	for y in range(GRID_ROWS):
		for x in range(GRID_COLUMNS):
			_configure_tile(atlas, Vector2i(x, y))

	var error: Error = ResourceSaver.save(tile_set, OUTPUT_PATH)
	if error != OK:
		push_error("Could not save prison TileSet: " + str(error))
		quit(1)
		return
	print("PRISON TILESET BUILT: " + OUTPUT_PATH + " (7x8, 56 selectable source assets)")
	quit(0)

func _configure_tile(atlas: TileSetAtlasSource, coords: Vector2i) -> void:
	var data: TileData = atlas.get_tile_data(coords, 0)
	if data == null:
		return
	data.set_custom_data("tile_role", _tile_role(coords))
	if not SOLID_TILES.has(coords):
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

func _tile_role(coords: Vector2i) -> String:
	if coords == Vector2i(0, 0) or coords == Vector2i(1, 0):
		return "floor"
	if coords == Vector2i(2, 0):
		return "wall_horizontal"
	if coords == Vector2i(0, 1):
		return "wall_vertical"
	if coords == Vector2i(1, 1):
		return "wall_corner"
	if coords == Vector2i(2, 2):
		return "door_frame"
	return "decoration"
