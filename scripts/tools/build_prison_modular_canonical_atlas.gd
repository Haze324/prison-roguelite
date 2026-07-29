extends SceneTree

## Locks every corner's connector pixels to the neighbouring straight-wall pixels.
## This is the mechanical guard against a black gap appearing at an L turn.
const SOURCE_PATH: String = "res://assets/generated/tilesets/industrial_prison/prison_modular_structure_48_v1.png"
const OUTPUT_PATH: String = "res://assets/generated/tilesets/industrial_prison/prison_modular_structure_48_v4.png"
const TILE_SIZE: int = 48
const EDGE_WIDTH: int = 4
const CORNER_BAND_WIDTH: int = 12

func _initialize() -> void:
	var source: Image = Image.load_from_file(ProjectSettings.globalize_path(SOURCE_PATH))
	if source == null or source.is_empty():
		push_error("Could not load generated modular structure atlas")
		quit(1)
		return
	var output: Image = source.duplicate()
	var horizontal_top: Image = _tile(source, Vector2i(1, 1))
	var horizontal_bottom: Image = _tile(source, Vector2i(9, 1))
	var vertical_left: Image = _tile(source, Vector2i(1, 2))
	var vertical_right: Image = _tile(source, Vector2i(9, 2))

	# Corners use a full straight-wall base rather than the AI sheet's framed corner art.
	# This prevents a decorative black void from becoming an actual gap in the room boundary.
	var top_left: Image = _overlay_corner_detail(horizontal_top, _tile(source, Vector2i(0, 5)))
	_overlay_vertical_band(top_left, vertical_left, true)
	_lock_right_edge(top_left, horizontal_top, true)
	_lock_bottom_edge(top_left, vertical_left, true)
	_write_tile(output, Vector2i(0, 5), top_left)

	var top_right: Image = _overlay_corner_detail(horizontal_top, _tile(source, Vector2i(1, 5)))
	_overlay_vertical_band(top_right, vertical_right, false)
	_lock_left_edge(top_right, horizontal_top, false)
	_lock_bottom_edge(top_right, vertical_right, true)
	_write_tile(output, Vector2i(1, 5), top_right)

	var bottom_right: Image = _overlay_corner_detail(horizontal_bottom, _tile(source, Vector2i(2, 5)))
	_overlay_vertical_band(bottom_right, vertical_right, false)
	_lock_left_edge(bottom_right, horizontal_bottom, false)
	_lock_top_edge(bottom_right, vertical_right, false)
	_write_tile(output, Vector2i(2, 5), bottom_right)

	var bottom_left: Image = _overlay_corner_detail(horizontal_bottom, _tile(source, Vector2i(3, 5)))
	_overlay_vertical_band(bottom_left, vertical_left, true)
	_lock_right_edge(bottom_left, horizontal_bottom, true)
	_lock_top_edge(bottom_left, vertical_left, false)
	_write_tile(output, Vector2i(3, 5), bottom_left)

	# At a corner's inner 4×4 pixel intersection the horizontal and vertical locks overlap.
	# Keep the vertical lock, then patch the corresponding straight-wall endpoint so both
	# directions share exactly the same pixels instead of merely looking close enough.
	_copy_patch(horizontal_top, Rect2i(0, TILE_SIZE - EDGE_WIDTH, EDGE_WIDTH, EDGE_WIDTH), top_left, Rect2i(TILE_SIZE - EDGE_WIDTH, TILE_SIZE - EDGE_WIDTH, EDGE_WIDTH, EDGE_WIDTH))
	_copy_patch(horizontal_top, Rect2i(TILE_SIZE - EDGE_WIDTH, TILE_SIZE - EDGE_WIDTH, EDGE_WIDTH, EDGE_WIDTH), top_right, Rect2i(0, TILE_SIZE - EDGE_WIDTH, EDGE_WIDTH, EDGE_WIDTH))
	_copy_patch(horizontal_bottom, Rect2i(TILE_SIZE - EDGE_WIDTH, 0, EDGE_WIDTH, EDGE_WIDTH), bottom_right, Rect2i(0, 0, EDGE_WIDTH, EDGE_WIDTH))
	_copy_patch(horizontal_bottom, Rect2i(0, 0, EDGE_WIDTH, EDGE_WIDTH), bottom_left, Rect2i(TILE_SIZE - EDGE_WIDTH, 0, EDGE_WIDTH, EDGE_WIDTH))
	_write_tile(output, Vector2i(1, 1), horizontal_top)
	_write_tile(output, Vector2i(9, 1), horizontal_bottom)

	# The next four cells repeat the edge-locked outer set for direct editor access.
	for x in range(4):
		_write_tile(output, Vector2i(4 + x, 5), _tile(output, Vector2i(x, 5)))
	var error: Error = output.save_png(ProjectSettings.globalize_path(OUTPUT_PATH))
	if error != OK:
		push_error("Could not save canonical modular structure atlas")
		quit(1)
		return
	print("CANONICAL MODULAR STRUCTURE ATLAS BUILT: corner edges locked")
	quit(0)

func _tile(image: Image, coords: Vector2i) -> Image:
	return image.get_region(Rect2i(coords * TILE_SIZE, Vector2i(TILE_SIZE, TILE_SIZE)))

func _write_tile(output: Image, coords: Vector2i, tile: Image) -> void:
	output.blit_rect(tile, Rect2i(Vector2i.ZERO, tile.get_size()), coords * TILE_SIZE)

func _copy_patch(destination: Image, destination_rect: Rect2i, source: Image, source_rect: Rect2i) -> void:
	var patch: Image = source.get_region(source_rect)
	destination.blit_rect(patch, Rect2i(Vector2i.ZERO, patch.get_size()), destination_rect.position)

func _overlay_corner_detail(base: Image, detail: Image) -> Image:
	var result: Image = base.duplicate()
	for y in range(TILE_SIZE):
		for x in range(TILE_SIZE):
			var pixel: Color = detail.get_pixel(x, y)
			if pixel.a > 0.1 and pixel.get_luminance() > 0.075:
				result.set_pixel(x, y, pixel)
	return result

func _overlay_vertical_band(corner: Image, vertical: Image, place_on_left: bool) -> void:
	var source_x: int = 0 if place_on_left else TILE_SIZE - CORNER_BAND_WIDTH
	var strip: Image = vertical.get_region(Rect2i(source_x, 0, CORNER_BAND_WIDTH, TILE_SIZE))
	var target_x: int = 0 if place_on_left else TILE_SIZE - CORNER_BAND_WIDTH
	corner.blit_rect(strip, Rect2i(Vector2i.ZERO, strip.get_size()), Vector2i(target_x, 0))

func _lock_right_edge(corner: Image, neighbour: Image, use_neighbour_left: bool) -> void:
	var source_x: int = 0 if use_neighbour_left else TILE_SIZE - EDGE_WIDTH
	var strip: Image = neighbour.get_region(Rect2i(source_x, 0, EDGE_WIDTH, TILE_SIZE))
	corner.blit_rect(strip, Rect2i(Vector2i.ZERO, strip.get_size()), Vector2i(TILE_SIZE - EDGE_WIDTH, 0))

func _lock_left_edge(corner: Image, neighbour: Image, use_neighbour_left: bool) -> void:
	var source_x: int = 0 if use_neighbour_left else TILE_SIZE - EDGE_WIDTH
	var strip: Image = neighbour.get_region(Rect2i(source_x, 0, EDGE_WIDTH, TILE_SIZE))
	corner.blit_rect(strip, Rect2i(Vector2i.ZERO, strip.get_size()), Vector2i.ZERO)

func _lock_bottom_edge(corner: Image, neighbour: Image, use_neighbour_top: bool) -> void:
	var source_y: int = 0 if use_neighbour_top else TILE_SIZE - EDGE_WIDTH
	var strip: Image = neighbour.get_region(Rect2i(0, source_y, TILE_SIZE, EDGE_WIDTH))
	corner.blit_rect(strip, Rect2i(Vector2i.ZERO, strip.get_size()), Vector2i(0, TILE_SIZE - EDGE_WIDTH))

func _lock_top_edge(corner: Image, neighbour: Image, use_neighbour_top: bool) -> void:
	var source_y: int = 0 if use_neighbour_top else TILE_SIZE - EDGE_WIDTH
	var strip: Image = neighbour.get_region(Rect2i(0, source_y, TILE_SIZE, EDGE_WIDTH))
	corner.blit_rect(strip, Rect2i(Vector2i.ZERO, strip.get_size()), Vector2i.ZERO)
