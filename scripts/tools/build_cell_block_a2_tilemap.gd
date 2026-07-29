extends SceneTree

## 生成 cell_block_a2 的手工 TileMapLayer 组合。
## 这里明确记录每一格，不使用房间矩形自动补四面墙的旧方案。
const TILE_SET_PATH: String = "res://resources/maps/prison_tileset_v1.tres"
const OUTPUT_PATH: String = "res://scenes/maps/cell_block_a2_tilemap.tscn"
const GRID_SIZE: Vector2i = Vector2i(35, 23)

const FLOOR_TILE: Vector2i = Vector2i(0, 0)
const CORRIDOR_TILE: Vector2i = Vector2i(1, 0)
const HORIZONTAL_WALL_TILE: Vector2i = Vector2i(0, 2)
const VERTICAL_WALL_TILE: Vector2i = Vector2i(1, 3)
const CORNER_TILE: Vector2i = Vector2i(2, 3)
const DOOR_TILE: Vector2i = Vector2i(3, 4)

func _initialize() -> void:
	var tile_set: TileSet = load(TILE_SET_PATH) as TileSet
	if tile_set == null:
		push_error("无法加载 TileSet: " + TILE_SET_PATH)
		quit(1)
		return

	var root: Node2D = Node2D.new()
	root.name = "CellBlockA2TileMap"
	root.set_meta("layout_mode", "manual_tilemap")
	root.set_meta("grid_size", GRID_SIZE)
	root.set_meta("source_of_truth", "Godot TileMapLayer cells")

	var floor_layer: TileMapLayer = TileMapLayer.new()
	floor_layer.name = "FloorLayer"
	floor_layer.z_index = -19
	floor_layer.tile_set = tile_set
	root.add_child(floor_layer)
	floor_layer.owner = root
	_paint_floor(floor_layer)

	var wall_layer: TileMapLayer = TileMapLayer.new()
	wall_layer.name = "WallLayer"
	wall_layer.z_index = -5
	wall_layer.tile_set = tile_set
	root.add_child(wall_layer)
	wall_layer.owner = root
	_paint_walls(wall_layer)

	var door_layer: TileMapLayer = TileMapLayer.new()
	door_layer.name = "DoorFrameLayer"
	door_layer.z_index = -4
	door_layer.tile_set = tile_set
	root.add_child(door_layer)
	door_layer.owner = root
	_paint_door_frames(door_layer)

	var packed_scene: PackedScene = PackedScene.new()
	var pack_error: Error = packed_scene.pack(root)
	if pack_error != OK:
		push_error("无法打包 cell_block_a2 TileMapLayer 场景: " + str(pack_error))
		root.free()
		quit(1)
		return
	var save_error: Error = ResourceSaver.save(packed_scene, OUTPUT_PATH)
	if save_error != OK:
		push_error("无法保存 cell_block_a2 TileMapLayer 场景: " + str(save_error))
		root.free()
		quit(1)
		return
	print("CELL BLOCK A2 TILEMAP BUILT: " + OUTPUT_PATH)
	root.free()
	quit(0)

func _paint_floor(layer: TileMapLayer) -> void:
	for y in range(GRID_SIZE.y):
		for x in range(GRID_SIZE.x):
			var cell: Vector2i = Vector2i(x, y)
			layer.set_cell(cell, 0, FLOOR_TILE)
	# 走廊使用另一种钢板地面，保持房间与交通空间一眼可分。
	for y in range(9, 18):
		for x in range(0, GRID_SIZE.x):
			layer.set_cell(Vector2i(x, y), 0, CORRIDOR_TILE)
	for x in range(11, 24):
		for y in range(0, GRID_SIZE.y):
			if y >= 9 and y <= 17:
				layer.set_cell(Vector2i(x, y), 0, CORRIDOR_TILE)

func _paint_walls(layer: TileMapLayer) -> void:
	# 外框是完整封闭边界，仅在明确的主通道位置留下门洞。
	_draw_room(layer, Rect2i(0, 0, GRID_SIZE.x - 1, GRID_SIZE.y - 1), [
		Vector2i(17, 0), Vector2i(17, 22), Vector2i(0, 11), Vector2i(34, 11),
	])
	# 六个房间均为独立手工边界，门洞位置是设计的一部分。
	_draw_room(layer, Rect2i(2, 2, 9, 7), [Vector2i(10, 5), Vector2i(6, 8)])
	_draw_room(layer, Rect2i(13, 2, 9, 7), [Vector2i(17, 8)])
	_draw_room(layer, Rect2i(24, 2, 9, 7), [Vector2i(24, 5), Vector2i(28, 8)])
	_draw_room(layer, Rect2i(13, 10, 9, 7), [
		Vector2i(17, 10), Vector2i(13, 13), Vector2i(21, 13), Vector2i(17, 16),
	])
	_draw_room(layer, Rect2i(2, 17, 9, 5), [Vector2i(10, 19)])
	_draw_room(layer, Rect2i(12, 18, 9, 4), [Vector2i(16, 18)])
	_draw_room(layer, Rect2i(24, 17, 9, 5), [Vector2i(24, 19)])

func _draw_room(layer: TileMapLayer, rect: Rect2i, openings: Array[Vector2i]) -> void:
	var left: int = rect.position.x
	var top: int = rect.position.y
	var right: int = rect.end.x - 1
	var bottom: int = rect.end.y - 1
	for x in range(left, right + 1):
		var top_cell: Vector2i = Vector2i(x, top)
		var bottom_cell: Vector2i = Vector2i(x, bottom)
		if not openings.has(top_cell):
			layer.set_cell(top_cell, 0, CORNER_TILE if x == left or x == right else HORIZONTAL_WALL_TILE)
		if not openings.has(bottom_cell):
			layer.set_cell(bottom_cell, 0, CORNER_TILE if x == left or x == right else HORIZONTAL_WALL_TILE)
	for y in range(top + 1, bottom):
		var left_cell: Vector2i = Vector2i(left, y)
		var right_cell: Vector2i = Vector2i(right, y)
		if not openings.has(left_cell):
			layer.set_cell(left_cell, 0, CORNER_TILE if y == top + 1 or y == bottom - 1 else VERTICAL_WALL_TILE)
		if not openings.has(right_cell):
			layer.set_cell(right_cell, 0, CORNER_TILE if y == top + 1 or y == bottom - 1 else VERTICAL_WALL_TILE)

func _paint_door_frames(layer: TileMapLayer) -> void:
	var door_cells: Array[Vector2i] = [
		Vector2i(10, 5), Vector2i(6, 8), Vector2i(17, 8), Vector2i(24, 5), Vector2i(28, 8),
		Vector2i(17, 10), Vector2i(13, 13), Vector2i(21, 13), Vector2i(17, 16),
		Vector2i(10, 19), Vector2i(16, 18), Vector2i(24, 19),
		Vector2i(17, 0), Vector2i(17, 22), Vector2i(0, 11), Vector2i(34, 11),
	]
	for cell in door_cells:
		layer.set_cell(cell, 0, DOOR_TILE)
