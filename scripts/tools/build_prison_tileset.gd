extends SceneTree

## Source 0 保留所有 12×12 原始单格，确保任意位置都可选择。
## Source 1 提供第 5～11 行已标准化的装饰，其中大型素材使用整数倍选择框。
const STRUCTURE_ATLAS_PATH: String = "res://assets/generated/tilesets/industrial_prison/prison_tileset_atlas_material_48_v4.png"
const PROPS_ATLAS_PATH: String = "res://assets/generated/tilesets/industrial_prison/prison_props_normalized_48_v7.png"
const OUTPUT_PATH: String = "res://resources/maps/prison_tileset_v1.tres"
const TILE_SIZE: Vector2i = Vector2i(48, 48)
const GRID_COLUMNS: int = 12
const GRID_ROWS: int = 12
const PROPS_ROWS: int = 7
const MULTI_PROP_RECTS: Array[Rect2i] = [
	Rect2i(2, 1, 2, 1), Rect2i(4, 1, 2, 1),
	Rect2i(0, 2, 2, 1), Rect2i(2, 2, 2, 1), Rect2i(4, 2, 2, 1),
	Rect2i(10, 3, 2, 1), Rect2i(9, 4, 2, 1),
	Rect2i(7, 5, 2, 1), Rect2i(9, 5, 2, 1),
	Rect2i(7, 6, 2, 1), Rect2i(9, 6, 2, 1),
]

func _initialize() -> void:
	var structure_texture: Texture2D = load(STRUCTURE_ATLAS_PATH) as Texture2D
	if structure_texture == null:
		push_error("无法加载基础图集: " + STRUCTURE_ATLAS_PATH)
		quit(1)
		return
	var props_texture: Texture2D = load(PROPS_ATLAS_PATH) as Texture2D
	if props_texture == null:
		push_error("无法加载标准化装饰图集: " + PROPS_ATLAS_PATH)
		quit(1)
		return

	var tile_set: TileSet = TileSet.new()
	tile_set.tile_size = TILE_SIZE
	tile_set.add_physics_layer()
	tile_set.set_physics_layer_collision_layer(0, 1)
	tile_set.set_physics_layer_collision_mask(0, 1)
	tile_set.add_occlusion_layer()
	tile_set.set_occlusion_layer_light_mask(0, 1)
	tile_set.add_custom_data_layer()
	tile_set.set_custom_data_layer_name(0, "tile_role")
	tile_set.set_custom_data_layer_type(0, TYPE_STRING)

	var structures: TileSetAtlasSource = TileSetAtlasSource.new()
	structures.texture = structure_texture
	structures.texture_region_size = TILE_SIZE
	for y in range(GRID_ROWS):
		for x in range(GRID_COLUMNS):
			structures.create_tile(Vector2i(x, y))
	tile_set.add_source(structures, 0)
	for y in range(GRID_ROWS):
		for x in range(GRID_COLUMNS):
			_configure_structure_tile(structures, Vector2i(x, y))

	var props: TileSetAtlasSource = TileSetAtlasSource.new()
	props.texture = props_texture
	props.texture_region_size = TILE_SIZE
	for rect: Rect2i in MULTI_PROP_RECTS:
		props.create_tile(rect.position, rect.size)
	for y in range(PROPS_ROWS):
		for x in range(GRID_COLUMNS):
			var cell: Vector2i = Vector2i(x, y)
			if _is_covered_by_multi(cell):
				continue
			props.create_tile(cell)
	tile_set.add_source(props, 1)
	for rect: Rect2i in MULTI_PROP_RECTS:
		var multi_data: TileData = props.get_tile_data(rect.position, 0)
		if multi_data != null:
			multi_data.set_custom_data("tile_role", "decoration_multicell")
	for y in range(PROPS_ROWS):
		for x in range(GRID_COLUMNS):
			var cell: Vector2i = Vector2i(x, y)
			if _is_covered_by_multi(cell):
				continue
			var prop_data: TileData = props.get_tile_data(cell, 0)
			if prop_data != null:
				prop_data.set_custom_data("tile_role", "decoration")

	var error: Error = ResourceSaver.save(tile_set, OUTPUT_PATH)
	if error != OK:
		push_error("保存 TileSet 失败: " + str(error))
		quit(1)
		return
	print("PRISON TILESET BUILT: " + OUTPUT_PATH)
	quit(0)

func _is_covered_by_multi(cell: Vector2i) -> bool:
	for rect: Rect2i in MULTI_PROP_RECTS:
		if rect.has_point(cell):
			return true
	return false

func _configure_structure_tile(atlas: TileSetAtlasSource, coords: Vector2i) -> void:
	var data: TileData = atlas.get_tile_data(coords, 0)
	if data == null:
		return
	data.set_custom_data("tile_role", _structure_role(coords))
	if coords != Vector2i(0, 2) and coords != Vector2i(1, 3) and coords != Vector2i(2, 3):
		return
	var half: float = float(TILE_SIZE.x) * 0.5
	var polygon: PackedVector2Array = PackedVector2Array([
		Vector2(-half, -half), Vector2(half, -half),
		Vector2(half, half), Vector2(-half, half),
	])
	data.set_collision_polygons_count(0, 1)
	data.set_collision_polygon_points(0, 0, polygon)
	var occluder: OccluderPolygon2D = OccluderPolygon2D.new()
	occluder.polygon = polygon
	data.set_occluder_polygons_count(0, 1)
	data.set_occluder_polygon(0, 0, occluder)

func _structure_role(coords: Vector2i) -> String:
	if coords == Vector2i(0, 0) or coords == Vector2i(1, 0):
		return "floor"
	if coords == Vector2i(0, 2):
		return "wall_horizontal"
	if coords == Vector2i(1, 3) or coords == Vector2i(2, 3):
		return "wall_vertical_or_corner"
	if coords == Vector2i(3, 4):
		return "door_frame"
	return "architecture_decoration"
