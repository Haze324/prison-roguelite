extends SceneTree

## Validates the final modular environment sources and the authored cell-block map.
const TILE_SET_PATH: String = "res://resources/maps/prison_tileset_v1.tres"
const TILEMAP_SCENE_PATH: String = "res://scenes/maps/cell_block_a2_tilemap.tscn"
const TILE_SIZE: int = 48
const CONNECTOR_WIDTH: int = 4
const REQUIRED_STRUCTURE_TILES: Array[Vector2i] = [
	Vector2i(0, 0), Vector2i(1, 1), Vector2i(9, 1),
	Vector2i(1, 2), Vector2i(9, 2),
	Vector2i(0, 5), Vector2i(1, 5), Vector2i(2, 5), Vector2i(3, 5),
]

func _initialize() -> void:
	var tile_set: TileSet = load(TILE_SET_PATH) as TileSet
	if tile_set == null:
		push_error("Modular TileSet audit failed: resource could not load")
		quit(1)
		return
	var structure: TileSetAtlasSource = tile_set.get_source(0) as TileSetAtlasSource
	var props: TileSetAtlasSource = tile_set.get_source(1) as TileSetAtlasSource
	var failures: Array[String] = []
	if structure == null or props == null:
		failures.append("missing structure or props source")
	else:
		if structure.texture_region_size != Vector2i(48, 48) or props.texture_region_size != Vector2i(48, 48):
			failures.append("atlas regions are not 48x48")
		if structure.get_tiles_count() != 128:
			failures.append("structure count=" + str(structure.get_tiles_count()))
		if props.get_tiles_count() != 64:
			failures.append("props count=" + str(props.get_tiles_count()))
		for coords in REQUIRED_STRUCTURE_TILES:
			if not structure.has_tile(coords):
				failures.append("missing structural tile=" + str(coords))
		var structure_image: Image = structure.texture.get_image()
		if structure_image == null or structure_image.is_empty():
			failures.append("structure texture pixels are unavailable for connector audit")
		else:
			_validate_corner_connectors(structure_image, failures)
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
		push_error("Modular TileSet audit failed: " + "; ".join(failures))
		quit(1)
		return
	print("MODULAR PRISON TILESET AUDIT PASS: structure=128 props=64 four-direction corners and map layers load")
	quit(0)

func _validate_corner_connectors(image: Image, failures: Array[String]) -> void:
	# Each row pair is a mechanical contract between a corner and a neighbouring straight wall.
	# A mismatch would recreate the dark seam that used to appear at L turns.
	if not _matches_vertical_strip(image, Vector2i(0, 5), TILE_SIZE - CONNECTOR_WIDTH, Vector2i(1, 1), 0):
		failures.append("top-left corner does not lock to top horizontal wall")
	if not _matches_horizontal_strip(image, Vector2i(0, 5), TILE_SIZE - CONNECTOR_WIDTH, Vector2i(1, 2), 0):
		failures.append("top-left corner does not lock to left vertical wall")
	if not _matches_vertical_strip(image, Vector2i(1, 5), 0, Vector2i(1, 1), TILE_SIZE - CONNECTOR_WIDTH):
		failures.append("top-right corner does not lock to top horizontal wall")
	if not _matches_horizontal_strip(image, Vector2i(1, 5), TILE_SIZE - CONNECTOR_WIDTH, Vector2i(9, 2), 0):
		failures.append("top-right corner does not lock to right vertical wall")
	if not _matches_vertical_strip(image, Vector2i(2, 5), 0, Vector2i(9, 1), TILE_SIZE - CONNECTOR_WIDTH):
		failures.append("bottom-right corner does not lock to bottom horizontal wall")
	if not _matches_horizontal_strip(image, Vector2i(2, 5), 0, Vector2i(9, 2), TILE_SIZE - CONNECTOR_WIDTH):
		failures.append("bottom-right corner does not lock to right vertical wall")
	if not _matches_vertical_strip(image, Vector2i(3, 5), TILE_SIZE - CONNECTOR_WIDTH, Vector2i(9, 1), 0):
		failures.append("bottom-left corner does not lock to bottom horizontal wall")
	if not _matches_horizontal_strip(image, Vector2i(3, 5), 0, Vector2i(1, 2), TILE_SIZE - CONNECTOR_WIDTH):
		failures.append("bottom-left corner does not lock to left vertical wall")

func _matches_vertical_strip(image: Image, first_tile: Vector2i, first_x: int, second_tile: Vector2i, second_x: int) -> bool:
	for y in range(TILE_SIZE):
		for offset in range(CONNECTOR_WIDTH):
			var first_pixel: Color = image.get_pixel(first_tile.x * TILE_SIZE + first_x + offset, first_tile.y * TILE_SIZE + y)
			var second_pixel: Color = image.get_pixel(second_tile.x * TILE_SIZE + second_x + offset, second_tile.y * TILE_SIZE + y)
			if not first_pixel.is_equal_approx(second_pixel):
				return false
	return true

func _matches_horizontal_strip(image: Image, first_tile: Vector2i, first_y: int, second_tile: Vector2i, second_y: int) -> bool:
	for x in range(TILE_SIZE):
		for offset in range(CONNECTOR_WIDTH):
			var first_pixel: Color = image.get_pixel(first_tile.x * TILE_SIZE + x, first_tile.y * TILE_SIZE + first_y + offset)
			var second_pixel: Color = image.get_pixel(second_tile.x * TILE_SIZE + x, second_tile.y * TILE_SIZE + second_y + offset)
			if not first_pixel.is_equal_approx(second_pixel):
				return false
	return true
