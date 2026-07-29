extends SceneTree

## 从原始 12×12 美术图逐格提取基础建筑材质。
## 每格固定输出为 48×48；装饰素材的视觉归一化由独立脚本处理。
const SOURCE_PATH: String = "res://assets/generated/tilesets/industrial_prison/prison_tileset_atlas_ai_v2.png"
const OUTPUT_PATH: String = "res://assets/generated/tilesets/industrial_prison/prison_tileset_atlas_material_48_v4.png"
const GRID_SIZE: int = 12
const TILE_SIZE: int = 48
const SOURCE_SIZE: int = 1254
const CROP_MARGIN: int = 2

func _initialize() -> void:
	var source: Image = Image.load_from_file(ProjectSettings.globalize_path(SOURCE_PATH))
	if source == null or source.is_empty():
		push_error("无法加载原始材质图集: " + SOURCE_PATH)
		quit(1)
		return
	var output: Image = Image.create(GRID_SIZE * TILE_SIZE, GRID_SIZE * TILE_SIZE, false, Image.FORMAT_RGBA8)
	for y in range(GRID_SIZE):
		for x in range(GRID_SIZE):
			var tile: Image = _extract_source_tile(source, Vector2i(x, y))
			tile.resize(TILE_SIZE, TILE_SIZE, Image.INTERPOLATE_NEAREST)
			output.blit_rect(tile, Rect2i(Vector2i.ZERO, Vector2i(TILE_SIZE, TILE_SIZE)), Vector2i(x * TILE_SIZE, y * TILE_SIZE))
	var error: Error = output.save_png(ProjectSettings.globalize_path(OUTPUT_PATH))
	if error != OK:
		push_error("保存基础材质图集失败: " + str(error))
		quit(1)
		return
	print("MATERIAL TILESET V4 EXTRACTED: " + OUTPUT_PATH)
	quit(0)

func _extract_source_tile(source: Image, cell: Vector2i) -> Image:
	var left: int = roundi(float(cell.x) * SOURCE_SIZE / GRID_SIZE) + CROP_MARGIN
	var top: int = roundi(float(cell.y) * SOURCE_SIZE / GRID_SIZE) + CROP_MARGIN
	var right: int = roundi(float(cell.x + 1) * SOURCE_SIZE / GRID_SIZE) - CROP_MARGIN
	var bottom: int = roundi(float(cell.y + 1) * SOURCE_SIZE / GRID_SIZE) - CROP_MARGIN
	var rect: Rect2i = Rect2i(left, top, maxi(right - left, 1), maxi(bottom - top, 1))
	var tile: Image = source.get_region(rect)
	tile.convert(Image.FORMAT_RGBA8)
	return tile
