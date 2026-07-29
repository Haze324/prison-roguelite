extends SceneTree

## 将 12×12 原材质图集注册为 48×48 TileSet。
## 使用外部纹理引用，避免把 PNG 内嵌进 .tres 后产生缓存/解析不一致。
const ATLAS_PATH: String = "res://assets/generated/tilesets/industrial_prison/prison_tileset_atlas_material_48_v4.png"
const OUTPUT_PATH: String = "res://resources/maps/prison_tileset_v1.tres"
const ATLAS_SIZE: int = 12
const REGION_SIZE: Vector2i = Vector2i(48, 48)
const MAP_TILE_SIZE: Vector2i = Vector2i(48, 48)

func _initialize() -> void:
	var texture: Texture2D = load(ATLAS_PATH) as Texture2D
	if texture == null:
		push_error("无法加载 TileSet 图集: " + ATLAS_PATH)
		quit(1)
		return

	var tile_set: TileSet = TileSet.new()
	tile_set.tile_size = MAP_TILE_SIZE
	tile_set.add_physics_layer()
	tile_set.set_physics_layer_collision_layer(0, 1)
	tile_set.set_physics_layer_collision_mask(0, 1)
	tile_set.add_occlusion_layer()
	tile_set.set_occlusion_layer_light_mask(0, 1)
	tile_set.add_custom_data_layer()
	tile_set.set_custom_data_layer_name(0, "tile_role")
	tile_set.set_custom_data_layer_type(0, TYPE_STRING)

	var atlas: TileSetAtlasSource = TileSetAtlasSource.new()
	atlas.texture = texture
	atlas.texture_region_size = REGION_SIZE
	for y in range(ATLAS_SIZE):
		for x in range(ATLAS_SIZE):
			atlas.create_tile(Vector2i(x, y))
	tile_set.add_source(atlas, 0)

	for y in range(ATLAS_SIZE):
		for x in range(ATLAS_SIZE):
			_configure_tile(atlas, Vector2i(x, y))

	var error: Error = ResourceSaver.save(tile_set, OUTPUT_PATH)
	if error != OK:
		push_error("保存 TileSet 失败: " + str(error))
		quit(1)
		return
	print("PRISON TILESET BUILT: " + OUTPUT_PATH)
	quit(0)

func _configure_tile(atlas: TileSetAtlasSource, coords: Vector2i) -> void:
	var tile_data: TileData = atlas.get_tile_data(coords, 0)
	if tile_data == null:
		return
	tile_data.set_custom_data("tile_role", _tile_role(coords))
	if not _is_solid_tile(coords):
		return
	var half: float = float(MAP_TILE_SIZE.x) * 0.5
	var polygon: PackedVector2Array = PackedVector2Array([
		Vector2(-half, -half), Vector2(half, -half),
		Vector2(half, half), Vector2(-half, half),
	])
	tile_data.set_collision_polygons_count(0, 1)
	tile_data.set_collision_polygon_points(0, 0, polygon)
	var occluder: OccluderPolygon2D = OccluderPolygon2D.new()
	occluder.polygon = polygon
	tile_data.set_occluder_polygons_count(0, 1)
	tile_data.set_occluder_polygon(0, 0, occluder)

func _is_solid_tile(coords: Vector2i) -> bool:
	return coords == Vector2i(0, 2) or coords == Vector2i(1, 2) or coords == Vector2i(2, 2) or coords == Vector2i(1, 3) or coords == Vector2i(2, 3)

func _tile_role(coords: Vector2i) -> String:
	if coords == Vector2i(0, 0) or coords == Vector2i(1, 0):
		return "floor"
	if coords == Vector2i(0, 2) or coords == Vector2i(1, 2):
		return "wall_horizontal"
	if coords == Vector2i(1, 3) or coords == Vector2i(2, 3):
		return "wall_vertical_or_corner"
	if coords.y == 6:
		return "warning_light"
	if coords.y == 7:
		return "power_light"
	if coords.y == 8:
		return "amber_light"
	return "decoration"
