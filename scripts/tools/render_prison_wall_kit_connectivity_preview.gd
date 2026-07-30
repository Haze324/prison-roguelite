extends SceneTree

## Renders an in-context preview of the four corners, T junctions and a cross junction.
const ATLAS_PATH: String = "res://assets/generated/tilesets/industrial_prison/prison_wall_kit_48_v1.png"
const OUTPUT_PATH: String = "res://assets/generated/tilesets/industrial_prison/prison_wall_kit_connectivity_preview_v1.png"
const TILE_SIZE: int = 48

func _initialize() -> void:
	var atlas: Image = Image.load_from_file(ProjectSettings.globalize_path(ATLAS_PATH))
	if atlas == null or atlas.is_empty():
		push_error("Could not load canonical wall kit")
		quit(1)
		return
	var output: Image = Image.create(20 * TILE_SIZE, 15 * TILE_SIZE, false, Image.FORMAT_RGBA8)
	output.fill(Color("101214"))
	for y in range(15):
		for x in range(20):
			_draw_tile(output, atlas, Vector2i(x, y), Vector2i(0, 0), false)
	_draw_room(output, atlas, Vector2i(1, 1), Vector2i(10, 6))
	_draw_tile(output, atlas, Vector2i(13, 2), Vector2i(0, 4), true)
	_draw_tile(output, atlas, Vector2i(14, 2), Vector2i(1, 4), true)
	_draw_tile(output, atlas, Vector2i(15, 2), Vector2i(2, 4), true)
	_draw_tile(output, atlas, Vector2i(16, 2), Vector2i(3, 4), true)
	_draw_tile(output, atlas, Vector2i(14, 3), Vector2i(4, 4), true)
	var error: Error = output.save_png(ProjectSettings.globalize_path(OUTPUT_PATH))
	if error != OK:
		push_error("Could not save wall kit connectivity preview")
		quit(1)
		return
	print("WALL KIT CONNECTIVITY PREVIEW BUILT: " + OUTPUT_PATH)
	quit(0)

func _draw_room(output: Image, atlas: Image, origin: Vector2i, size: Vector2i) -> void:
	for y in range(size.y):
		for x in range(size.x):
			_draw_tile(output, atlas, origin + Vector2i(x, y), Vector2i(0, 0), false)
	for x in range(1, size.x - 1):
		_draw_tile(output, atlas, origin + Vector2i(x, 0), Vector2i(0, 1), true)
		_draw_tile(output, atlas, origin + Vector2i(x, size.y - 1), Vector2i(4, 1), true)
	for y in range(1, size.y - 1):
		_draw_tile(output, atlas, origin + Vector2i(0, y), Vector2i(0, 2), true)
		_draw_tile(output, atlas, origin + Vector2i(size.x - 1, y), Vector2i(4, 2), true)
	_draw_tile(output, atlas, origin, Vector2i(0, 3), true)
	_draw_tile(output, atlas, origin + Vector2i(size.x - 1, 0), Vector2i(1, 3), true)
	_draw_tile(output, atlas, origin + Vector2i(size.x - 1, size.y - 1), Vector2i(2, 3), true)
	_draw_tile(output, atlas, origin + Vector2i(0, size.y - 1), Vector2i(3, 3), true)

func _draw_tile(output: Image, atlas: Image, destination: Vector2i, source: Vector2i, blend: bool) -> void:
	var tile: Image = atlas.get_region(Rect2i(source * TILE_SIZE, Vector2i(TILE_SIZE, TILE_SIZE)))
	if blend:
		output.blend_rect(tile, Rect2i(Vector2i.ZERO, tile.get_size()), destination * TILE_SIZE)
	else:
		output.blit_rect(tile, Rect2i(Vector2i.ZERO, tile.get_size()), destination * TILE_SIZE)
