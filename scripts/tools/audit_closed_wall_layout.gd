extends SceneTree

## Headless QA audit for the authored cell_block_a2 wall layout.
##
## This script is intentionally read-only. It treats WallLayer as the solid
## wall source and DoorFrameLayer as an explicit, authored opening marker.
## The room rectangles below mirror the current manual TileMap contract in
## build_cell_block_a2_tilemap.gd; this is not an auto-wall generator.

const TILE_SET_PATH: String = "res://resources/maps/prison_tileset_v1.tres"
const TILEMAP_SCENE_PATH: String = "res://scenes/maps/cell_block_a2_tilemap.tscn"
const TILE_SIZE: int = 48
const CANONICAL_WALL_WIDTH: int = 32
const STRUCTURE_SOURCE_ID: int = 0
const DOOR_ROLE: String = "door_frame"

const OUTER_RECT: Rect2i = Rect2i(0, 0, 35, 23)

const ROOM_LAYOUTS: Array[Dictionary] = [
	{"name": "outer_frame", "rect": OUTER_RECT, "openings": [Vector2i(17, 0), Vector2i(17, 22), Vector2i(0, 11), Vector2i(34, 11)]},
	{"name": "room_1", "rect": Rect2i(2, 2, 9, 7), "openings": [Vector2i(10, 5), Vector2i(6, 8)]},
	{"name": "room_2", "rect": Rect2i(13, 2, 9, 7), "openings": [Vector2i(17, 8)]},
	{"name": "room_3", "rect": Rect2i(24, 2, 9, 7), "openings": [Vector2i(24, 5), Vector2i(28, 8)]},
	{"name": "room_4", "rect": Rect2i(13, 10, 9, 7), "openings": [Vector2i(17, 10), Vector2i(13, 13), Vector2i(21, 13), Vector2i(17, 16)]},
	{"name": "room_5", "rect": Rect2i(2, 17, 9, 5), "openings": [Vector2i(10, 19)]},
	{"name": "room_6", "rect": Rect2i(12, 18, 9, 4), "openings": [Vector2i(16, 18)]},
	{"name": "room_7", "rect": Rect2i(24, 17, 9, 5), "openings": [Vector2i(24, 19)]},
]

const STRUCTURE_MASKS: Dictionary = {
	Vector2i(0, 1): 1,
	Vector2i(4, 1): 4,
	Vector2i(0, 2): 8,
	Vector2i(4, 2): 2,
	Vector2i(0, 3): 9,
	Vector2i(1, 3): 3,
	Vector2i(2, 3): 6,
	Vector2i(3, 3): 12,
	Vector2i(0, 4): 11,
	Vector2i(1, 4): 14,
	Vector2i(2, 4): 7,
	Vector2i(3, 4): 13,
	Vector2i(4, 4): 15,
	Vector2i(0, 5): 1,
	Vector2i(1, 5): 2,
	Vector2i(2, 5): 4,
	Vector2i(3, 5): 8,
}

func _initialize() -> void:
	var failures: Array[String] = []
	var tile_set: TileSet = load(TILE_SET_PATH) as TileSet
	var structure_source: TileSetAtlasSource = null
	if tile_set == null:
		failures.append("TileSet load failed: " + TILE_SET_PATH)
	else:
		if tile_set.tile_size != Vector2i(TILE_SIZE, TILE_SIZE):
			failures.append("TileSet tile_size=" + str(tile_set.tile_size) + ", expected (48, 48)")
		structure_source = tile_set.get_source(STRUCTURE_SOURCE_ID) as TileSetAtlasSource
		if structure_source == null:
			failures.append("TileSet structure source 0 is missing")
		else:
			_audit_structure_atlas(structure_source, failures)

	var tilemap_scene: PackedScene = load(TILEMAP_SCENE_PATH) as PackedScene
	if tilemap_scene == null:
		failures.append("TileMap scene load failed: " + TILEMAP_SCENE_PATH)
	else:
		var tilemap_root: Node = tilemap_scene.instantiate()
		if tilemap_root == null:
			failures.append("TileMap scene could not instantiate")
		else:
			var wall_layer: TileMapLayer = tilemap_root.get_node_or_null("WallLayer") as TileMapLayer
			var door_layer: TileMapLayer = tilemap_root.get_node_or_null("DoorFrameLayer") as TileMapLayer
			if wall_layer == null:
				failures.append("WallLayer is missing")
			if door_layer == null:
				failures.append("DoorFrameLayer is missing")
			if wall_layer != null and door_layer != null and structure_source != null:
				_audit_map_layers(wall_layer, door_layer, structure_source, failures)
			tilemap_root.free()

	if failures.is_empty():
		print("CLOSED WALL AUDIT PASS: 48px grid; 32px canonical wall width; outer frame and 7 rooms closed with authored door openings")
		quit(0)
		return

	print("CLOSED WALL AUDIT FAIL: " + str(failures.size()) + " issue(s)")
	for failure in failures:
		push_error("CLOSED WALL AUDIT: " + failure)
	quit(1)

func _audit_structure_atlas(source: TileSetAtlasSource, failures: Array[String]) -> void:
	if source.texture_region_size != Vector2i(TILE_SIZE, TILE_SIZE):
		failures.append("structure atlas region=" + str(source.texture_region_size) + ", expected (48, 48)")
	if source.texture == null:
		failures.append("structure atlas texture is missing")
		return
	var image: Image = source.texture.get_image()
	if image == null or image.is_empty():
		failures.append("structure atlas pixels are unavailable")
		return
	for coords: Vector2i in STRUCTURE_MASKS:
		var tile_data: TileData = source.get_tile_data(coords, 0)
		if tile_data == null:
			failures.append("missing structural tile=" + str(coords))
			continue
		var role: Variant = tile_data.get_custom_data("tile_role")
		if str(role).is_empty():
			failures.append("structural tile has no tile_role=" + str(coords))
		var mask: int = int(STRUCTURE_MASKS[coords])
		if not _tile_matches_mask(image, coords, mask):
			failures.append("32px wall geometry mismatch at tile=" + str(coords) + " mask=" + str(mask))

func _tile_matches_mask(image: Image, coords: Vector2i, mask: int) -> bool:
	var origin: Vector2i = coords * TILE_SIZE
	for y in range(TILE_SIZE):
		for x in range(TILE_SIZE):
			var expected_opaque: bool = _inside_mask(x, y, mask)
			var actual_opaque: bool = image.get_pixel(origin.x + x, origin.y + y).a > 0.05
			if expected_opaque != actual_opaque:
				return false
	return true

func _inside_mask(x: int, y: int, mask: int) -> bool:
	if (mask & 1) != 0 and y < CANONICAL_WALL_WIDTH:
		return true
	if (mask & 2) != 0 and x >= TILE_SIZE - CANONICAL_WALL_WIDTH:
		return true
	if (mask & 4) != 0 and y >= TILE_SIZE - CANONICAL_WALL_WIDTH:
		return true
	if (mask & 8) != 0 and x < CANONICAL_WALL_WIDTH:
		return true
	return false

func _audit_map_layers(wall_layer: TileMapLayer, door_layer: TileMapLayer, source: TileSetAtlasSource, failures: Array[String]) -> void:
	_audit_layer_grid(wall_layer, "WallLayer", failures)
	_audit_layer_grid(door_layer, "DoorFrameLayer", failures)

	var wall_cells: Dictionary = _collect_cells(wall_layer, source, false, failures)
	var door_cells: Dictionary = _collect_cells(door_layer, source, true, failures)
	for cell: Vector2i in door_cells:
		if wall_cells.has(cell):
			failures.append("wall and door overlap at cell=" + str(cell))

	var expected_wall: Dictionary = {}
	var expected_doors: Dictionary = {}
	for layout: Dictionary in ROOM_LAYOUTS:
		var rect: Rect2i = layout["rect"] as Rect2i
		var openings: Array = layout["openings"] as Array
		for cell: Vector2i in _boundary_cells(rect):
			if openings.has(cell):
				expected_doors[cell] = layout["name"]
			else:
				expected_wall[cell] = layout["name"]
		_audit_boundary(layout["name"], rect, openings, wall_cells, door_cells, failures)

	for cell: Vector2i in wall_cells:
		if not expected_wall.has(cell):
			failures.append("unexpected wall tile outside authored room boundaries at cell=" + str(cell))
	for cell: Vector2i in door_cells:
		if not expected_doors.has(cell):
			failures.append("unexpected door frame outside authored openings at cell=" + str(cell))

func _audit_layer_grid(layer: TileMapLayer, layer_name: String, failures: Array[String]) -> void:
	if layer.tile_set == null:
		failures.append(layer_name + " has no TileSet")
		return
	if layer.position.x != 0.0 or layer.position.y != 0.0:
		failures.append(layer_name + " position is not anchored at the 48px grid origin: " + str(layer.position))
	if layer.rotation != 0.0:
		failures.append(layer_name + " is rotated")
	if layer.scale != Vector2.ONE:
		failures.append(layer_name + " scale is not 1:1: " + str(layer.scale))
	if layer.tile_set.tile_size != Vector2i(TILE_SIZE, TILE_SIZE):
		failures.append(layer_name + " TileSet tile_size is not (48, 48)")
	for cell: Vector2i in layer.get_used_cells():
		var local_position: Vector2 = layer.map_to_local(cell)
		var expected_position: Vector2 = Vector2(cell.x * TILE_SIZE + TILE_SIZE / 2, cell.y * TILE_SIZE + TILE_SIZE / 2)
		if not local_position.is_equal_approx(expected_position):
			failures.append(layer_name + " cell is not on 48px grid at cell=" + str(cell) + " local=" + str(local_position))

func _collect_cells(layer: TileMapLayer, source: TileSetAtlasSource, require_door_role: bool, failures: Array[String]) -> Dictionary:
	var cells: Dictionary = {}
	for cell: Vector2i in layer.get_used_cells():
		var source_id: int = layer.get_cell_source_id(cell)
		if source_id != STRUCTURE_SOURCE_ID:
			failures.append("unexpected source=" + str(source_id) + " in " + layer.name + " at cell=" + str(cell))
			continue
		var atlas_coords: Vector2i = layer.get_cell_atlas_coords(cell)
		var tile_data: TileData = source.get_tile_data(atlas_coords, layer.get_cell_alternative_tile(cell))
		if tile_data == null:
			failures.append("missing TileData for " + layer.name + " at cell=" + str(cell) + " atlas=" + str(atlas_coords))
			continue
		var role: String = str(tile_data.get_custom_data("tile_role"))
		if require_door_role and role not in [DOOR_ROLE, "wall_horizontal_top", "wall_horizontal_bottom", "wall_vertical_left", "wall_vertical_right"]:
			failures.append("DoorFrameLayer tile role=" + role + " at cell=" + str(cell) + ", expected a directional wall/door role")
		if not require_door_role and not STRUCTURE_MASKS.has(atlas_coords):
			failures.append("WallLayer contains non-structural atlas tile=" + str(atlas_coords) + " at cell=" + str(cell))
		cells[cell] = role
	return cells

func _audit_boundary(layout_name: String, rect: Rect2i, openings: Array, wall_cells: Dictionary, door_cells: Dictionary, failures: Array[String]) -> void:
	for cell: Vector2i in _boundary_cells(rect):
		var is_opening: bool = openings.has(cell)
		var has_wall: bool = wall_cells.has(cell)
		var has_door: bool = door_cells.has(cell)
		if is_opening:
			if has_wall or not has_door:
				failures.append(layout_name + " authored opening is not a door frame at cell=" + str(cell))
		else:
			if not has_wall or has_door:
				failures.append(layout_name + " wall boundary has a gap or unexpected door at cell=" + str(cell))

func _boundary_cells(rect: Rect2i) -> Array[Vector2i]:
	var cells: Array[Vector2i] = []
	var left: int = rect.position.x
	var top: int = rect.position.y
	var right: int = rect.end.x - 1
	var bottom: int = rect.end.y - 1
	for x in range(left, right + 1):
		cells.append(Vector2i(x, top))
		if bottom != top:
			cells.append(Vector2i(x, bottom))
	for y in range(top + 1, bottom):
		cells.append(Vector2i(left, y))
		if right != left:
			cells.append(Vector2i(right, y))
	return cells
