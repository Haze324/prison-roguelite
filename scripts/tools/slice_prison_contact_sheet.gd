extends SceneTree

## The 1024px image is a contact sheet, not a regular tile atlas.
## Each rectangle below was measured from the original art's visible frame.
const SOURCE_PATH: String = "res://assets/generated/tilesets/industrial_prison/prison_tileset_atlas_1024.png"
const OUTPUT_PATH: String = "res://assets/generated/tilesets/industrial_prison/prison_tileset_sliced_48_v6.png"
const TILE_SIZE: int = 48
const COLUMN_STARTS: Array[int] = [24, 165, 306, 447, 588, 729, 870]
const ROW_STARTS: Array[int] = [25, 167, 309, 453, 572, 693, 809, 918]
const ROW_HEIGHTS: Array[int] = [130, 130, 132, 109, 109, 105, 97, 82]
const CELL_WIDTH: int = 130

func _initialize() -> void:
	var source: Image = Image.load_from_file(ProjectSettings.globalize_path(SOURCE_PATH))
	if source == null or source.is_empty():
		push_error("Could not load prison contact sheet: " + SOURCE_PATH)
		quit(1)
		return
	var output: Image = Image.create(COLUMN_STARTS.size() * TILE_SIZE, ROW_STARTS.size() * TILE_SIZE, false, Image.FORMAT_RGBA8)
	# Keep the original contact sheet's dark backing instead of exposing transparent gaps.
	output.fill(Color("151719"))
	for row in range(ROW_STARTS.size()):
		for column in range(COLUMN_STARTS.size()):
			var source_rect: Rect2i = Rect2i(COLUMN_STARTS[column], ROW_STARTS[row], CELL_WIDTH, ROW_HEIGHTS[row])
			var cell: Image = source.get_region(source_rect)
			cell.convert(Image.FORMAT_RGBA8)
			var scale_ratio: float = min(float(TILE_SIZE) / float(cell.get_width()), float(TILE_SIZE) / float(cell.get_height()))
			var target_size: Vector2i = Vector2i(
				maxi(1, roundi(float(cell.get_width()) * scale_ratio)),
				maxi(1, roundi(float(cell.get_height()) * scale_ratio))
			)
			cell.resize(target_size.x, target_size.y, Image.INTERPOLATE_NEAREST)
			var offset: Vector2i = Vector2i(
				column * TILE_SIZE + int((TILE_SIZE - target_size.x) / 2),
				row * TILE_SIZE + int((TILE_SIZE - target_size.y) / 2)
			)
			output.blit_rect(cell, Rect2i(Vector2i.ZERO, cell.get_size()), offset)
	var error: Error = output.save_png(ProjectSettings.globalize_path(OUTPUT_PATH))
	if error != OK:
		push_error("Could not save sliced prison atlas: " + str(error))
		quit(1)
		return
	print("PRISON CONTACT SHEET SLICED: " + OUTPUT_PATH + " (7x8, 56 complete source assets)")
	quit(0)
