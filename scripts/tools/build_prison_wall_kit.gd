extends SceneTree

## Builds the canonical wall kit from one approved material source.
## Every wall band is exactly 32 px inside a 48 px cell; masks describe the occupied edges.
const SOURCE_PATH: String = "res://assets/generated/tilesets/industrial_prison/prison_tileset_atlas_material_48_v4.png"
const OUTPUT_PATH: String = "res://assets/generated/tilesets/industrial_prison/prison_wall_kit_48_v1.png"
const PREVIEW_PATH: String = "res://assets/generated/tilesets/industrial_prison/prison_wall_kit_preview_v1.png"
const TILE_SIZE: int = 48
const WALL_WIDTH: int = 32
const SOURCE_GRID_COLUMNS: int = 12
const SOURCE_GRID_ROWS: int = 12
const SOURCE_BORDER: int = 0
const ATLAS_COLUMNS: int = 8
const ATLAS_ROWS: int = 6

const MASK_N: int = 1
const MASK_E: int = 2
const MASK_S: int = 4
const MASK_W: int = 8

func _initialize() -> void:
	var source: Image = Image.load_from_file(ProjectSettings.globalize_path(SOURCE_PATH))
	if source == null or source.is_empty():
		push_error("Could not load approved prison wall material source")
		quit(1)
		return
	var atlas: Image = Image.create(ATLAS_COLUMNS * TILE_SIZE, ATLAS_ROWS * TILE_SIZE, false, Image.FORMAT_RGBA8)
	atlas.fill(Color.TRANSPARENT)
	# Rebuild the horizontal cross-section from two approved source cells: the
	# upper cell supplies the metal lip, while the next cell supplies the wall
	# face. This keeps the original art direction but prevents the wall body
	# from disappearing into the floor at runtime.
	var horizontal_band: Image = _build_horizontal_wall_band(source)
	var horizontal_bottom_band: Image = horizontal_band.duplicate()
	horizontal_bottom_band.flip_y()
	var vertical_band: Image = horizontal_band.duplicate()
	vertical_band.rotate_90(ClockDirection.CLOCKWISE)
	var vertical_right_band: Image = vertical_band.duplicate()
	vertical_right_band.flip_x()
	var floor_variants: Array[Image] = []
	for x in range(4):
		var floor: Image = _structure_tile(source, Vector2i(x, 0))
		floor_variants.append(floor)
		_write_tile(atlas, Vector2i(x, 0), floor)

	# Row 1: horizontal boundary bands. Row 2: vertical boundary bands.
	for x in range(4):
		_write_tile(atlas, Vector2i(x, 1), _make_mask_tile(MASK_N, horizontal_band, horizontal_bottom_band, vertical_band, vertical_right_band, floor_variants[x]))
		_write_tile(atlas, Vector2i(x + 4, 1), _make_mask_tile(MASK_S, horizontal_band, horizontal_bottom_band, vertical_band, vertical_right_band, floor_variants[x]))
		_write_tile(atlas, Vector2i(x, 2), _make_mask_tile(MASK_W, horizontal_band, horizontal_bottom_band, vertical_band, vertical_right_band, floor_variants[x]))
		_write_tile(atlas, Vector2i(x + 4, 2), _make_mask_tile(MASK_E, horizontal_band, horizontal_bottom_band, vertical_band, vertical_right_band, floor_variants[x]))

	# Row 3: the four room corners. NW/NE/SE/SW are actual two-edge joins.
	_write_tile(atlas, Vector2i(0, 3), _make_mask_tile(MASK_N | MASK_W, horizontal_band, horizontal_bottom_band, vertical_band, vertical_right_band, floor_variants[0]))
	_write_tile(atlas, Vector2i(1, 3), _make_mask_tile(MASK_N | MASK_E, horizontal_band, horizontal_bottom_band, vertical_band, vertical_right_band, floor_variants[1]))
	_write_tile(atlas, Vector2i(2, 3), _make_mask_tile(MASK_S | MASK_E, horizontal_band, horizontal_bottom_band, vertical_band, vertical_right_band, floor_variants[2]))
	_write_tile(atlas, Vector2i(3, 3), _make_mask_tile(MASK_S | MASK_W, horizontal_band, horizontal_bottom_band, vertical_band, vertical_right_band, floor_variants[3]))

	# Row 4: T junctions and the four-way junction.
	_write_tile(atlas, Vector2i(0, 4), _make_mask_tile(MASK_N | MASK_E | MASK_W, horizontal_band, horizontal_bottom_band, vertical_band, vertical_right_band, floor_variants[0]))
	_write_tile(atlas, Vector2i(1, 4), _make_mask_tile(MASK_E | MASK_S | MASK_W, horizontal_band, horizontal_bottom_band, vertical_band, vertical_right_band, floor_variants[1]))
	_write_tile(atlas, Vector2i(2, 4), _make_mask_tile(MASK_N | MASK_E | MASK_S, horizontal_band, horizontal_bottom_band, vertical_band, vertical_right_band, floor_variants[2]))
	_write_tile(atlas, Vector2i(3, 4), _make_mask_tile(MASK_N | MASK_S | MASK_W, horizontal_band, horizontal_bottom_band, vertical_band, vertical_right_band, floor_variants[3]))
	_write_tile(atlas, Vector2i(4, 4), _make_mask_tile(MASK_N | MASK_E | MASK_S | MASK_W, horizontal_band, horizontal_bottom_band, vertical_band, vertical_right_band, floor_variants[0]))

	# Row 5: single-edge caps, useful for corridor ends and deliberate wall stops.
	_write_tile(atlas, Vector2i(0, 5), _make_mask_tile(MASK_N, horizontal_band, horizontal_bottom_band, vertical_band, vertical_right_band, floor_variants[0]))
	_write_tile(atlas, Vector2i(1, 5), _make_mask_tile(MASK_E, horizontal_band, horizontal_bottom_band, vertical_band, vertical_right_band, floor_variants[1]))
	_write_tile(atlas, Vector2i(2, 5), _make_mask_tile(MASK_S, horizontal_band, horizontal_bottom_band, vertical_band, vertical_right_band, floor_variants[2]))
	_write_tile(atlas, Vector2i(3, 5), _make_mask_tile(MASK_W, horizontal_band, horizontal_bottom_band, vertical_band, vertical_right_band, floor_variants[3]))

	var save_error: Error = atlas.save_png(ProjectSettings.globalize_path(OUTPUT_PATH))
	if save_error != OK:
		push_error("Could not save canonical wall kit")
		quit(1)
		return
	_render_preview(atlas)
	print("PRISON WALL KIT BUILT: 48x48 cells, wall_width=32, corners=4, junctions=5, caps=4")
	quit(0)

func _structure_tile(source: Image, coords: Vector2i) -> Image:
	var x0: int = floori(float(coords.x) * float(source.get_width()) / float(SOURCE_GRID_COLUMNS)) + SOURCE_BORDER
	var y0: int = floori(float(coords.y) * float(source.get_height()) / float(SOURCE_GRID_ROWS)) + SOURCE_BORDER
	var x1: int = floori(float(coords.x + 1) * float(source.get_width()) / float(SOURCE_GRID_COLUMNS)) - SOURCE_BORDER
	var y1: int = floori(float(coords.y + 1) * float(source.get_height()) / float(SOURCE_GRID_ROWS)) - SOURCE_BORDER
	var cell: Image = source.get_region(Rect2i(x0, y0, x1 - x0, y1 - y0))
	cell.convert(Image.FORMAT_RGBA8)
	cell.resize(TILE_SIZE, TILE_SIZE, Image.INTERPOLATE_NEAREST)
	return cell

func _make_mask_tile(mask: int, top_band: Image, bottom_band: Image, left_band: Image, right_band: Image, floor: Image) -> Image:
	var tile: Image = Image.create(TILE_SIZE, TILE_SIZE, false, Image.FORMAT_RGBA8)
	tile.fill(Color.TRANSPARENT)
	if mask & MASK_N:
		tile.blit_rect(top_band, Rect2i(Vector2i.ZERO, top_band.get_size()), Vector2i.ZERO)
	if mask & MASK_S:
		tile.blit_rect(bottom_band, Rect2i(Vector2i.ZERO, bottom_band.get_size()), Vector2i(0, TILE_SIZE - WALL_WIDTH))
	if mask & MASK_W:
		tile.blit_rect(left_band, Rect2i(Vector2i.ZERO, left_band.get_size()), Vector2i.ZERO)
	if mask & MASK_E:
		tile.blit_rect(right_band, Rect2i(Vector2i.ZERO, right_band.get_size()), Vector2i(TILE_SIZE - WALL_WIDTH, 0))
	return tile

func _build_horizontal_wall_band(source: Image) -> Image:
	var top_material: Image = _structure_tile(source, Vector2i(7, 0))
	var face_material: Image = _structure_tile(source, Vector2i(7, 1))
	var band: Image = Image.create(TILE_SIZE, WALL_WIDTH, false, Image.FORMAT_RGBA8)
	for y in range(WALL_WIDTH):
		var source_image: Image = face_material
		var source_y: int = 0
		var factor: float = 1.0
		var lift: float = 0.0
		if y < 8:
			source_image = top_material
			source_y = mini(y * 2, TILE_SIZE - 1)
			factor = 1.10
			lift = 0.02
		elif y < 26:
			source_y = clampi(4 + (y - 8) * 2, 0, TILE_SIZE - 1)
			factor = 1.22
			lift = 0.025
		else:
			source_y = clampi(36 + (y - 26) * 2, 0, TILE_SIZE - 1)
			factor = 0.52
		for x in range(TILE_SIZE):
			var pixel: Color = source_image.get_pixel(x, source_y)
			pixel = _shade_lift(pixel, factor, lift)
			pixel.a = 1.0
			band.set_pixel(x, y, pixel)
	return band

func _shade_lift(pixel: Color, factor: float, lift: float) -> Color:
	return Color(
		clampf(pixel.r * factor + lift, 0.0, 1.0),
		clampf(pixel.g * factor + lift, 0.0, 1.0),
		clampf(pixel.b * factor + lift, 0.0, 1.0),
		pixel.a,
	)

func _write_tile(atlas: Image, coords: Vector2i, tile: Image) -> void:
	atlas.blit_rect(tile, Rect2i(Vector2i.ZERO, tile.get_size()), coords * TILE_SIZE)

func _render_preview(atlas: Image) -> void:
	var preview: Image = Image.create(ATLAS_COLUMNS * TILE_SIZE, ATLAS_ROWS * TILE_SIZE, false, Image.FORMAT_RGBA8)
	preview.fill(Color("15191c"))
	for y in range(ATLAS_ROWS):
		for x in range(ATLAS_COLUMNS):
			var tile: Image = atlas.get_region(Rect2i(Vector2i(x, y) * TILE_SIZE, Vector2i(TILE_SIZE, TILE_SIZE)))
			preview.blit_rect(tile, Rect2i(Vector2i.ZERO, tile.get_size()), Vector2i(x, y) * TILE_SIZE)
	var error: Error = preview.save_png(ProjectSettings.globalize_path(PREVIEW_PATH))
	if error != OK:
		push_error("Could not save wall kit preview")
