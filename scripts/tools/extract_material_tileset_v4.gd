extends SceneTree

## 保留原工业监狱材质，按原图真实 16×16 网格逐格裁切并统一为 48×48。
const SOURCE_PATH: String = "res://assets/generated/tilesets/industrial_prison/prison_tileset_atlas_ai_v2.png"
const OUTPUT_PATH: String = "res://assets/generated/tilesets/industrial_prison/prison_tileset_atlas_material_48_v4.png"
const GRID_SIZE: int = 12
const TILE_SIZE: int = 48
const SOURCE_SIZE: int = 1254
const CROP_MARGIN: int = 2

func _initialize() -> void:
	var source: Image = Image.load_from_file(ProjectSettings.globalize_path(SOURCE_PATH))
	if source == null or source.is_empty():
		push_error("无法加载原材质图集: " + SOURCE_PATH)
		quit(1)
		return
	var output: Image = Image.create(GRID_SIZE * TILE_SIZE, GRID_SIZE * TILE_SIZE, false, Image.FORMAT_RGBA8)
	for y in range(GRID_SIZE):
		for x in range(GRID_SIZE):
			var source_left: int = roundi(float(x) * SOURCE_SIZE / GRID_SIZE) + CROP_MARGIN
			var source_top: int = roundi(float(y) * SOURCE_SIZE / GRID_SIZE) + CROP_MARGIN
			var source_right: int = roundi(float(x + 1) * SOURCE_SIZE / GRID_SIZE) - CROP_MARGIN
			var source_bottom: int = roundi(float(y + 1) * SOURCE_SIZE / GRID_SIZE) - CROP_MARGIN
			var crop_rect: Rect2i = Rect2i(source_left, source_top, maxi(source_right - source_left, 1), maxi(source_bottom - source_top, 1))
			var tile: Image = source.get_region(crop_rect)
			tile.convert(Image.FORMAT_RGBA8)
			tile.resize(TILE_SIZE, TILE_SIZE, Image.INTERPOLATE_NEAREST)
			output.blit_rect(tile, Rect2i(Vector2i.ZERO, Vector2i(TILE_SIZE, TILE_SIZE)), Vector2i(x * TILE_SIZE, y * TILE_SIZE))
	var error: Error = output.save_png(ProjectSettings.globalize_path(OUTPUT_PATH))
	if error != OK:
		push_error("无法保存原材质逐格图集: " + OUTPUT_PATH)
		quit(1)
		return
	print("MATERIAL TILESET V4 EXTRACTED: " + OUTPUT_PATH)
	quit(0)
