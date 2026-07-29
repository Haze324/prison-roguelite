extends SceneTree

## Renders four complete rooms from the generated modular atlas.
## Every preview uses all four wall directions and all four corner directions.
const ATLAS_PATH: String = "res://assets/generated/tilesets/industrial_prison/prison_modular_structure_48_v4.png"
const OUTPUT_PATH: String = "res://assets/generated/tilesets/industrial_prison/prison_modular_seam_preview_v4.png"
const TILE_SIZE: int = 48
const ROOM_SIZE: int = 6

func _initialize() -> void:
	var atlas: Image = Image.load_from_file(ProjectSettings.globalize_path(ATLAS_PATH))
	if atlas == null or atlas.is_empty():
		push_error("Could not load modular structure atlas")
		quit(1)
		return
	var preview: Image = Image.create(ROOM_SIZE * TILE_SIZE * 2, ROOM_SIZE * TILE_SIZE * 2, false, Image.FORMAT_RGBA8)
	preview.fill(Color("101214"))
	for variant in range(4):
		_draw_room(preview, atlas, Vector2i((variant % 2) * ROOM_SIZE, (variant / 2) * ROOM_SIZE), variant)
	var error: Error = preview.save_png(ProjectSettings.globalize_path(OUTPUT_PATH))
	if error != OK:
		push_error("Could not save seam preview")
		quit(1)
		return
	print("MODULAR PRISON SEAM PREVIEW BUILT: " + OUTPUT_PATH)
	quit(0)

func _draw_room(output: Image, atlas: Image, origin: Vector2i, variant: int) -> void:
	for y in range(ROOM_SIZE):
		for x in range(ROOM_SIZE):
			_draw_tile(output, atlas, origin + Vector2i(x, y), Vector2i((x + y + variant) % 8, 0))
	for x in range(1, ROOM_SIZE - 1):
		_draw_tile(output, atlas, origin + Vector2i(x, 0), Vector2i((x + variant) % 8, 1))
		_draw_tile(output, atlas, origin + Vector2i(x, ROOM_SIZE - 1), Vector2i((x + variant) % 8 + 8, 1))
	for y in range(1, ROOM_SIZE - 1):
		_draw_tile(output, atlas, origin + Vector2i(0, y), Vector2i((y + variant) % 8, 2))
		_draw_tile(output, atlas, origin + Vector2i(ROOM_SIZE - 1, y), Vector2i((y + variant) % 8 + 8, 2))
	# Every room uses the semantically correct four corners: TL, TR, BR, BL.
	_draw_tile(output, atlas, origin, Vector2i(0, 5))
	_draw_tile(output, atlas, origin + Vector2i(ROOM_SIZE - 1, 0), Vector2i(1, 5))
	_draw_tile(output, atlas, origin + Vector2i(ROOM_SIZE - 1, ROOM_SIZE - 1), Vector2i(2, 5))
	_draw_tile(output, atlas, origin + Vector2i(0, ROOM_SIZE - 1), Vector2i(3, 5))

func _draw_tile(output: Image, atlas: Image, destination: Vector2i, source: Vector2i) -> void:
	var tile: Image = atlas.get_region(Rect2i(source * TILE_SIZE, Vector2i(TILE_SIZE, TILE_SIZE)))
	output.blit_rect(tile, Rect2i(Vector2i.ZERO, tile.get_size()), destination * TILE_SIZE)
