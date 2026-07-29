extends SceneTree

## 从 12×12 美术图集中提取可用于 TileMap 的完整结构瓦片。
## 灯具、管道等跨格装饰不进入该图集，避免被误画进 FloorLayer。
const SOURCE_PATH: String = "res://assets/generated/tilesets/industrial_prison/prison_tileset_atlas_material_48_v4.png"
const OUTPUT_PATH: String = "res://assets/generated/tilesets/industrial_prison/prison_structure_atlas_48_v5.png"
const TILE_SIZE: int = 48
const SOURCE_CELLS: Array[Vector2i] = [
	Vector2i(0, 0), Vector2i(1, 0), Vector2i(0, 2),
	Vector2i(1, 3), Vector2i(2, 3), Vector2i(3, 4),
]

func _initialize() -> void:
	var source: Image = Image.load_from_file(ProjectSettings.globalize_path(SOURCE_PATH))
	if source == null or source.is_empty():
		push_error("无法加载结构瓦片源图: " + SOURCE_PATH)
		quit(1)
		return
	var output: Image = Image.create(TILE_SIZE * 3, TILE_SIZE * 2, false, Image.FORMAT_RGBA8)
	for index in range(SOURCE_CELLS.size()):
		var source_cell: Vector2i = SOURCE_CELLS[index]
		var source_rect: Rect2i = Rect2i(source_cell * TILE_SIZE, Vector2i(TILE_SIZE, TILE_SIZE))
		var tile: Image = source.get_region(source_rect)
		tile.convert(Image.FORMAT_RGBA8)
		var target: Vector2i = Vector2i(index % 3, index / 3) * TILE_SIZE
		output.blit_rect(tile, Rect2i(Vector2i.ZERO, Vector2i(TILE_SIZE, TILE_SIZE)), target)
	var error: Error = output.save_png(ProjectSettings.globalize_path(OUTPUT_PATH))
	if error != OK:
		push_error("保存结构瓦片图失败: " + str(error))
		quit(1)
		return
	print("PRISON STRUCTURE ATLAS BUILT: " + OUTPUT_PATH)
	quit(0)
