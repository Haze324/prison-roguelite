extends SceneTree

## Validates the canonical 48px wall kit, its 16px edge geometry, and the authored map.
const TILE_SET_PATH: String = "res://resources/maps/prison_tileset_v1.tres"
const TILEMAP_SCENE_PATH: String = "res://scenes/maps/cell_block_a2_tilemap.tscn"
const TILE_SIZE: int = 48
const WALL_WIDTH: int = 16
const REQUIRED_STRUCTURE_TILES: Array[Vector2i] = [
	Vector2i(0, 0), Vector2i(3, 0),
	Vector2i(0, 1), Vector2i(4, 1), Vector2i(0, 2), Vector2i(4, 2),
	Vector2i(0, 3), Vector2i(1, 3), Vector2i(2, 3), Vector2i(3, 3),
	Vector2i(0, 4), Vector2i(1, 4), Vector2i(2, 4), Vector2i(3, 4), Vector2i(4, 4), Vector2i(5, 4),
	Vector2i(0, 5), Vector2i(1, 5), Vector2i(2, 5), Vector2i(3, 5),
]

func _initialize() -> void:
	var tile_set: TileSet = load(TILE_SET_PATH) as TileSet
	var failures: Array[String] = []
	if tile_set == null:
		failures.append("TileSet resource could not load")
	else:
		var structure: TileSetAtlasSource = tile_set.get_source(0) as TileSetAtlasSource
		var props: TileSetAtlasSource = tile_set.get_source(1) as TileSetAtlasSource
		if structure == null or props == null:
			failures.append("missing structure or props source")
		else:
			if structure.texture_region_size != Vector2i(TILE_SIZE, TILE_SIZE) or props.texture_region_size != Vector2i(TILE_SIZE, TILE_SIZE):
				failures.append("atlas regions are not 48x48")
			if structure.get_tiles_count() != 34:
				failures.append("wall kit count=" + str(structure.get_tiles_count()) + ", expected 34")
			if props.get_tiles_count() != 81:
				failures.append("props count=" + str(props.get_tiles_count()) + ", expected 81")
			for coords in REQUIRED_STRUCTURE_TILES:
				if not structure.has_tile(coords):
					failures.append("missing wall kit tile=" + str(coords))
			_validate_roles(structure, failures)
			var structure_image: Image = structure.texture.get_image()
			if structure_image == null or structure_image.is_empty():
				failures.append("wall kit pixels unavailable")
			else:
				_validate_geometry(structure_image, failures)
			var prop_data: TileData = props.get_tile_data(Vector2i(0, 0), 0)
			if prop_data == null or prop_data.get_custom_data("tile_role") != "wall_prop_overlay":
				failures.append("props are not registered as overlays")

	var tilemap_scene: PackedScene = load(TILEMAP_SCENE_PATH) as PackedScene
	if tilemap_scene == null:
		failures.append("tilemap scene could not load")
	else:
		var tilemap_root: Node2D = tilemap_scene.instantiate() as Node2D
		var floor_layer: TileMapLayer = tilemap_root.get_node_or_null("FloorLayer") as TileMapLayer
		var wall_layer: TileMapLayer = tilemap_root.get_node_or_null("WallLayer") as TileMapLayer
		var door_layer: TileMapLayer = tilemap_root.get_node_or_null("DoorFrameLayer") as TileMapLayer
		if floor_layer == null or wall_layer == null or door_layer == null:
			failures.append("tilemap layers missing")
		elif floor_layer.get_used_cells().is_empty() or wall_layer.get_used_cells().is_empty() or door_layer.get_used_cells().is_empty():
			failures.append("tilemap layers are not painted")
		tilemap_root.free()
	if not failures.is_empty():
		push_error("Wall kit audit failed: " + "; ".join(failures))
		quit(1)
		return
	print("WALL KIT AUDIT PASS: 34 structural tiles, 16px wall width, four corners and five junctions connect")
	quit(0)

func _validate_roles(structure: TileSetAtlasSource, failures: Array[String]) -> void:
	var expected: Dictionary = {
		Vector2i(0, 1): ["wall_horizontal_top", 1],
		Vector2i(4, 1): ["wall_horizontal_bottom", 4],
		Vector2i(0, 2): ["wall_vertical_left", 8],
		Vector2i(4, 2): ["wall_vertical_right", 2],
		Vector2i(0, 3): ["wall_corner", 9],
		Vector2i(1, 3): ["wall_corner", 3],
		Vector2i(2, 3): ["wall_corner", 6],
		Vector2i(3, 3): ["wall_corner", 12],
		Vector2i(4, 4): ["wall_cross_junction", 15],
		Vector2i(5, 4): ["door_frame", 1],
	}
	for coords in expected:
		var data: TileData = structure.get_tile_data(coords, 0)
		var expected_values: Array = expected[coords]
		if data == null or data.get_custom_data("tile_role") != expected_values[0] or data.get_custom_data("connection_mask") != expected_values[1]:
			failures.append("metadata mismatch at=" + str(coords))

func _validate_geometry(image: Image, failures: Array[String]) -> void:
	# These masks are the contract used by the palette and later Terrain integration.
	var masks: Dictionary = {
		Vector2i(0, 1): 1, Vector2i(4, 1): 4,
		Vector2i(0, 2): 8, Vector2i(4, 2): 2,
		Vector2i(0, 3): 9, Vector2i(1, 3): 3, Vector2i(2, 3): 6, Vector2i(3, 3): 12,
		Vector2i(0, 4): 11, Vector2i(1, 4): 14, Vector2i(2, 4): 7, Vector2i(3, 4): 13, Vector2i(4, 4): 15,
		Vector2i(0, 5): 1, Vector2i(1, 5): 2, Vector2i(2, 5): 4, Vector2i(3, 5): 8,
	}
	for coords in masks:
		var mask: int = masks[coords]
		for y in range(TILE_SIZE):
			for x in range(TILE_SIZE):
				var expected_opaque: bool = _inside_mask(x, y, mask)
				var actual_opaque: bool = image.get_pixel(coords.x * TILE_SIZE + x, coords.y * TILE_SIZE + y).a > 0.05
				if expected_opaque != actual_opaque:
					failures.append("geometry mask mismatch at=" + str(coords) + " pixel=" + str(Vector2i(x, y)))
					return

func _inside_mask(x: int, y: int, mask: int) -> bool:
	if (mask & 1) != 0 and y < WALL_WIDTH:
		return true
	if (mask & 2) != 0 and x >= TILE_SIZE - WALL_WIDTH:
		return true
	if (mask & 4) != 0 and y >= TILE_SIZE - WALL_WIDTH:
		return true
	if (mask & 8) != 0 and x < WALL_WIDTH:
		return true
	return false
