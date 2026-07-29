extends SceneTree

## Converts the two AI-produced 8x8 master sheets into clean, gap-free Godot atlases.
## Structure cells have a dark contact-sheet border; it is trimmed before every tile is normalized.
const STRUCTURE_RAW_PATH: String = "res://assets/generated/tilesets/industrial_prison/prison_modular_structure_raw_v1.png"
const PROPS_RAW_PATH: String = "res://assets/generated/tilesets/industrial_prison/prison_modular_props_alpha_v1.png"
const STRUCTURE_OUTPUT_PATH: String = "res://assets/generated/tilesets/industrial_prison/prison_modular_structure_48_v1.png"
const PROPS_OUTPUT_PATH: String = "res://assets/generated/tilesets/industrial_prison/prison_modular_props_48_v1.png"
const TILE_SIZE: int = 48
const SOURCE_CELL_SIZE: int = 128
const SOURCE_BORDER: int = 5
const SOURCE_INTERIOR_SIZE: int = 118
const OUTPUT_COLUMNS: int = 16
const OUTPUT_ROWS: int = 8

func _initialize() -> void:
	var structure_raw: Image = Image.load_from_file(ProjectSettings.globalize_path(STRUCTURE_RAW_PATH))
	var props_raw: Image = Image.load_from_file(ProjectSettings.globalize_path(PROPS_RAW_PATH))
	if structure_raw == null or structure_raw.is_empty() or props_raw == null or props_raw.is_empty():
		push_error("Could not load modular prison master sheets")
		quit(1)
		return
	var structure_atlas: Image = Image.create(OUTPUT_COLUMNS * TILE_SIZE, OUTPUT_ROWS * TILE_SIZE, false, Image.FORMAT_RGBA8)
	structure_atlas.fill(Color("101214"))
	_build_structure_atlas(structure_raw, structure_atlas)
	var props_atlas: Image = Image.create(8 * TILE_SIZE, 8 * TILE_SIZE, false, Image.FORMAT_RGBA8)
	props_atlas.fill(Color.TRANSPARENT)
	_build_props_atlas(props_raw, props_atlas)
	var structure_error: Error = structure_atlas.save_png(ProjectSettings.globalize_path(STRUCTURE_OUTPUT_PATH))
	var props_error: Error = props_atlas.save_png(ProjectSettings.globalize_path(PROPS_OUTPUT_PATH))
	if structure_error != OK or props_error != OK:
		push_error("Could not save modular prison atlases")
		quit(1)
		return
	print("MODULAR PRISON ATLASES BUILT: structure=16x8, props=8x8")
	quit(0)

func _build_structure_atlas(source: Image, output: Image) -> void:
	# Row 0: seamless floors.
	for x in range(8):
		_write_tile(output, Vector2i(x, 0), _structure_tile(source, Vector2i(x, 0)))
		_write_tile(output, Vector2i(x + 8, 0), _structure_tile(source, Vector2i(x, 6)))
	# Rows 1-4: the same straight wall band in all four cardinal orientations.
	for x in range(8):
		var straight: Image = _structure_tile(source, Vector2i(x, 1))
		_write_tile(output, Vector2i(x, 1), straight)
		_write_tile(output, Vector2i(x + 8, 1), _rotated(straight, 2))
		_write_tile(output, Vector2i(x, 2), _rotated(straight, 1))
		_write_tile(output, Vector2i(x + 8, 2), _rotated(straight, 3))
		var damaged: Image = _structure_tile(source, Vector2i(x, 7))
		_write_tile(output, Vector2i(x, 3), damaged)
		_write_tile(output, Vector2i(x + 8, 3), _rotated(damaged, 2))
		_write_tile(output, Vector2i(x, 4), _rotated(damaged, 1))
		_write_tile(output, Vector2i(x + 8, 4), _rotated(damaged, 3))
	# Row 5: outer corners. Each variant is explicitly rotated from the same master corner.
	for x in range(4):
		var outer_corner: Image = _structure_tile(source, Vector2i(x, 3))
		for rotation in range(4):
			_write_tile(output, Vector2i(x * 4 + rotation, 5), _rotated(outer_corner, rotation))
	# Row 6: inner corners and junction pieces, also with all cardinal rotations present.
	for x in range(4):
		var inner_corner: Image = _structure_tile(source, Vector2i(x, 4))
		for rotation in range(4):
			_write_tile(output, Vector2i(x * 4 + rotation, 6), _rotated(inner_corner, rotation))
	# Row 7: doorways, caps, solid wall panels and structural alternates from the master sheet.
	for x in range(8):
		_write_tile(output, Vector2i(x, 7), _structure_tile(source, Vector2i(x, 5)))
		_write_tile(output, Vector2i(x + 8, 7), _structure_tile(source, Vector2i(x, 2)))

func _build_props_atlas(source: Image, output: Image) -> void:
	for y in range(8):
		for x in range(8):
			var cell: Image = source.get_region(Rect2i(x * SOURCE_CELL_SIZE, y * SOURCE_CELL_SIZE, SOURCE_CELL_SIZE, SOURCE_CELL_SIZE))
			cell.convert(Image.FORMAT_RGBA8)
			cell.resize(TILE_SIZE, TILE_SIZE, Image.INTERPOLATE_NEAREST)
			_write_tile(output, Vector2i(x, y), cell)

func _structure_tile(source: Image, coords: Vector2i) -> Image:
	var position: Vector2i = coords * SOURCE_CELL_SIZE + Vector2i(SOURCE_BORDER, SOURCE_BORDER)
	var cell: Image = source.get_region(Rect2i(position, Vector2i(SOURCE_INTERIOR_SIZE, SOURCE_INTERIOR_SIZE)))
	cell.convert(Image.FORMAT_RGBA8)
	cell.resize(TILE_SIZE, TILE_SIZE, Image.INTERPOLATE_NEAREST)
	return cell

func _rotated(source: Image, quarter_turns_clockwise: int) -> Image:
	var copy: Image = source.duplicate()
	for _turn in range(quarter_turns_clockwise):
		copy.rotate_90(ClockDirection.CLOCKWISE)
	return copy

func _write_tile(output: Image, coords: Vector2i, tile: Image) -> void:
	output.blit_rect(tile, Rect2i(Vector2i.ZERO, tile.get_size()), coords * TILE_SIZE)
