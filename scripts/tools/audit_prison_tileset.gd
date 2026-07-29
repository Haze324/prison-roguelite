extends SceneTree

## 验证工业监狱 TileSet：基础源必须完整可选，装饰源的跨格素材必须以整数倍图块注册。
const TILE_SET_PATH: String = "res://resources/maps/prison_tileset_v1.tres"
const EXPECTED_BASE_TILES: int = 144
const EXPECTED_PROP_TILES: int = 73
const MULTI_PROP_RECTS: Array[Rect2i] = [
	Rect2i(2, 1, 2, 1), Rect2i(4, 1, 2, 1),
	Rect2i(0, 2, 2, 1), Rect2i(2, 2, 2, 1), Rect2i(4, 2, 2, 1),
	Rect2i(10, 3, 2, 1), Rect2i(9, 4, 2, 1),
	Rect2i(7, 5, 2, 1), Rect2i(9, 5, 2, 1),
	Rect2i(7, 6, 2, 1), Rect2i(9, 6, 2, 1),
]

func _initialize() -> void:
	var tile_set: TileSet = load(TILE_SET_PATH) as TileSet
	if tile_set == null:
		push_error("TileSet audit failed: resource could not load")
		quit(1)
		return
	var base: TileSetAtlasSource = tile_set.get_source(0) as TileSetAtlasSource
	var props: TileSetAtlasSource = tile_set.get_source(1) as TileSetAtlasSource
	if base == null or props == null:
		push_error("TileSet audit failed: missing base or props source")
		quit(1)
		return
	var failures: Array[String] = []
	if base.get_tiles_count() != EXPECTED_BASE_TILES:
		failures.append("base count=" + str(base.get_tiles_count()))
	if props.get_tiles_count() != EXPECTED_PROP_TILES:
		failures.append("props count=" + str(props.get_tiles_count()))
	for y in range(12):
		for x in range(12):
			if not base.has_tile(Vector2i(x, y)):
				failures.append("base missing=" + str(Vector2i(x, y)))
	for rect: Rect2i in MULTI_PROP_RECTS:
		if not props.has_tile(rect.position):
			failures.append("multi prop missing=" + str(rect.position))
		elif props.get_tile_size_in_atlas(rect.position) != rect.size:
			failures.append("multi prop size invalid=" + str(rect.position))
	if not failures.is_empty():
		push_error("TileSet audit failed: " + "; ".join(failures))
		quit(1)
		return
	print("PRISON TILESET AUDIT PASS: base=144 props=73 multi=11")
	quit(0)
