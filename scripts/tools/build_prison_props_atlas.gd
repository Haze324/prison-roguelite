extends SceneTree

## 将原图第 5 至 11 行的装饰主体规范化为透明 48×48 单元。
const SOURCE_PATH: String = "res://assets/generated/tilesets/industrial_prison/prison_tileset_atlas_material_48_v4.png"
const OUTPUT_PATH: String = "res://assets/generated/tilesets/industrial_prison/prison_props_normalized_48_v7.png"
const TILE_SIZE: int = 48
const COLUMNS: int = 12
const FIRST_SOURCE_ROW: int = 4
const LAST_SOURCE_ROW: int = 10
const TARGET_SIZE: int = 42

func _initialize() -> void:
	var source: Image = Image.load_from_file(ProjectSettings.globalize_path(SOURCE_PATH))
	if source == null or source.is_empty():
		push_error("无法加载基础材质图集: " + SOURCE_PATH)
		quit(1)
		return
	var rows: int = LAST_SOURCE_ROW - FIRST_SOURCE_ROW + 1
	var output: Image = Image.create(COLUMNS * TILE_SIZE, rows * TILE_SIZE, false, Image.FORMAT_RGBA8)
	output.fill(Color(0.0, 0.0, 0.0, 0.0))
	for source_row in range(FIRST_SOURCE_ROW, LAST_SOURCE_ROW + 1):
		for x in range(COLUMNS):
			var source_tile: Image = source.get_region(Rect2i(x * TILE_SIZE, source_row * TILE_SIZE, TILE_SIZE, TILE_SIZE))
			var normalized: Image = _normalize_prop(source_tile)
			var target_y: int = (source_row - FIRST_SOURCE_ROW) * TILE_SIZE
			output.blit_rect(normalized, Rect2i(Vector2i.ZERO, Vector2i(TILE_SIZE, TILE_SIZE)), Vector2i(x * TILE_SIZE, target_y))
	var error: Error = output.save_png(ProjectSettings.globalize_path(OUTPUT_PATH))
	if error != OK:
		push_error("保存标准化装饰图集失败: " + str(error))
		quit(1)
		return
	print("PRISON PROPS ATLAS BUILT: " + OUTPUT_PATH)
	quit(0)

func _normalize_prop(source_tile: Image) -> Image:
	var bounds: Rect2i = _find_bounds(source_tile)
	if bounds.size.x <= 0 or bounds.size.y <= 0:
		bounds = Rect2i(0, 0, TILE_SIZE, TILE_SIZE)
	var content: Image = _isolate(source_tile, bounds)
	var scale: float = minf(float(TARGET_SIZE) / float(content.get_width()), float(TARGET_SIZE) / float(content.get_height()))
	var target_size: Vector2i = Vector2i(maxi(roundi(float(content.get_width()) * scale), 1), maxi(roundi(float(content.get_height()) * scale), 1))
	content.resize(target_size.x, target_size.y, Image.INTERPOLATE_NEAREST)
	var canvas: Image = Image.create(TILE_SIZE, TILE_SIZE, false, Image.FORMAT_RGBA8)
	canvas.fill(Color(0.0, 0.0, 0.0, 0.0))
	var position: Vector2i = Vector2i((TILE_SIZE - target_size.x) / 2, (TILE_SIZE - target_size.y) / 2)
	canvas.blit_rect(content, Rect2i(Vector2i.ZERO, target_size), position)
	return canvas

func _find_bounds(image: Image) -> Rect2i:
	var min_x: int = TILE_SIZE
	var min_y: int = TILE_SIZE
	var max_x: int = -1
	var max_y: int = -1
	for y in range(TILE_SIZE):
		for x in range(TILE_SIZE):
			if _is_foreground(image.get_pixel(x, y)):
				min_x = mini(min_x, x)
				min_y = mini(min_y, y)
				max_x = maxi(max_x, x)
				max_y = maxi(max_y, y)
	if max_x < min_x or max_y < min_y:
		return Rect2i()
	var margin: int = 3
	var left: int = maxi(min_x - margin, 0)
	var top: int = maxi(min_y - margin, 0)
	var right: int = mini(max_x + margin + 1, TILE_SIZE)
	var bottom: int = mini(max_y + margin + 1, TILE_SIZE)
	return Rect2i(left, top, right - left, bottom - top)

func _isolate(image: Image, bounds: Rect2i) -> Image:
	var content: Image = Image.create(bounds.size.x, bounds.size.y, false, Image.FORMAT_RGBA8)
	for y in range(bounds.size.y):
		for x in range(bounds.size.x):
			var source_x: int = bounds.position.x + x
			var source_y: int = bounds.position.y + y
			if _near_foreground(image, source_x, source_y):
				content.set_pixel(x, y, image.get_pixel(source_x, source_y))
			else:
				content.set_pixel(x, y, Color(0.0, 0.0, 0.0, 0.0))
	return content

func _near_foreground(image: Image, center_x: int, center_y: int) -> bool:
	for offset_y in range(-4, 5):
		for offset_x in range(-4, 5):
			var sample_x: int = center_x + offset_x
			var sample_y: int = center_y + offset_y
			if sample_x < 0 or sample_y < 0 or sample_x >= TILE_SIZE or sample_y >= TILE_SIZE:
				continue
			if _is_foreground(image.get_pixel(sample_x, sample_y)):
				return true
	return false

func _is_foreground(color: Color) -> bool:
	var maximum: float = maxf(color.r, maxf(color.g, color.b))
	var minimum: float = minf(color.r, minf(color.g, color.b))
	return maximum >= 0.34 or (maximum >= 0.18 and maximum - minimum >= 0.12)
