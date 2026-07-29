extends SceneTree

## Validates that every original contact-sheet asset maps to exactly one selectable TileSet cell.
const TILE_SET_PATH: String = "res://resources/maps/prison_tileset_v1.tres"
const TILEMAP_SCENE_PATH: String = "res://scenes/maps/cell_block_a2_tilemap.tscn"
const EXPECTED_TILE_COUNT: int = 56
const REQUIRED_TILES: Array[Vector2i] = [
	Vector2i(0, 0), Vector2i(1, 0), Vector2i(2, 0),
	Vector2i(0, 1), Vector2i(1, 1), Vector2i(2, 2),
]

func _initialize() -> void:
	var tile_set: TileSet = load(TILE_SET_PATH) as TileSet
	if tile_set == null:
		push_error("TileSet audit failed: resource could not load")
		quit(1)
		return
	var atlas: TileSetAtlasSource = tile_set.get_source(0) as TileSetAtlasSource
	if atlas == null:
		push_error("TileSet audit failed: source 0 is missing")
		quit(1)
		return
	var failures: Array[String] = []
	if tile_set.get_source_count() != 1:
		failures.append("source count=" + str(tile_set.get_source_count()))
	if atlas.texture_region_size != Vector2i(48, 48):
		failures.append("atlas region=" + str(atlas.texture_region_size))
	if atlas.get_tiles_count() != EXPECTED_TILE_COUNT:
		failures.append("tile count=" + str(atlas.get_tiles_count()))
	for y in range(8):
		for x in range(7):
			if not atlas.has_tile(Vector2i(x, y)):
				failures.append("missing=" + str(Vector2i(x, y)))
	for coords in REQUIRED_TILES:
		if not atlas.has_tile(coords):
			failures.append("required tile missing=" + str(coords))
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
		push_error("TileSet audit failed: " + "; ".join(failures))
		quit(1)
		return
	print("PRISON TILESET AUDIT PASS: 7x8, 56 source assets, one selectable cell per asset, tilemap loads")
	quit(0)
