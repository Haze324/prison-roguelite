class_name MapGenerator
extends Node2D

@export var map_seed: int = 0

var obstacle_rects: Array[Rect2] = []
var room_rects: Array[Rect2] = []
var corridor_rects: Array[Rect2] = []
var fixed_power_nodes: Dictionary = {}
var safehouse_known: bool = false
var safehouse_position: Vector2 = Vector2.ZERO

func generate(new_seed: int = 0) -> void:
	map_seed = new_seed if new_seed != 0 else randi()
	for child in get_children():
		child.queue_free()
	obstacle_rects.clear()
	room_rects.clear()
	corridor_rects.clear()
	fixed_power_nodes.clear()
	safehouse_known = false
	var rng: RandomNumberGenerator = RandomNumberGenerator.new()
	rng.seed = map_seed
	var anchors: Array[Vector2] = [
		Vector2(36.0, 50.0),
		Vector2(470.0, 50.0),
		Vector2(940.0, 50.0),
		Vector2(80.0, 420.0),
		Vector2(560.0, 420.0),
		Vector2(1080.0, 430.0),
	]
	for anchor in anchors:
		var room_size: Vector2 = Vector2(rng.randf_range(340.0, 430.0), rng.randf_range(230.0, 290.0))
		var room_position: Vector2 = anchor + Vector2(rng.randf_range(-18.0, 18.0), rng.randf_range(-14.0, 14.0))
		room_position.x = clampf(room_position.x, 24.0, 1680.0 - room_size.x - 24.0)
		room_position.y = clampf(room_position.y, 32.0, 1080.0 - room_size.y - 32.0)
		room_rects.append(Rect2(room_position, room_size))
	_build_corridor_loop()
	var candidates: Array[Rect2] = _build_obstacle_candidates()
	for candidate in candidates:
		if rng.randf() < 0.15 or _overlaps_key_point(candidate):
			continue
		_add_obstacle(candidate)
	for room in room_rects:
		if rng.randf() < 0.65:
			var cover_size: Vector2 = Vector2(rng.randf_range(90.0, 170.0), rng.randf_range(24.0, 38.0))
			var cover_position: Vector2 = room.position + Vector2(
				rng.randf_range(46.0, maxf(47.0, room.size.x - cover_size.x - 46.0)),
				rng.randf_range(70.0, maxf(71.0, room.size.y - cover_size.y - 70.0))
			)
			var cover_rect: Rect2 = Rect2(cover_position, cover_size)
			if not _overlaps_key_point(cover_rect):
				_add_obstacle(cover_rect)
	queue_redraw()
	EventBus.map_generated.emit(map_seed, 1)

func _build_corridor_loop() -> void:
	if room_rects.size() < 2:
		return
	var links: Array[Vector2i] = [
		Vector2i(0, 1),
		Vector2i(1, 2),
		Vector2i(2, 5),
		Vector2i(5, 4),
		Vector2i(4, 3),
		Vector2i(3, 0),
	]
	for link in links:
		var start: Vector2 = room_rects[link.x].get_center()
		var end: Vector2 = room_rects[link.y].get_center()
		var horizontal: Rect2 = Rect2(minf(start.x, end.x) - 18.0, start.y - 18.0, absf(end.x - start.x) + 36.0, 36.0)
		var vertical: Rect2 = Rect2(end.x - 18.0, minf(start.y, end.y) - 18.0, 36.0, absf(end.y - start.y) + 36.0)
		corridor_rects.append(horizontal)
		corridor_rects.append(vertical)

func _build_obstacle_candidates() -> Array[Rect2]:
	return [
		Rect2(540.0, 170.0, 180.0, 34.0),
		Rect2(820.0, 300.0, 36.0, 220.0),
		Rect2(1040.0, 150.0, 220.0, 34.0),
		Rect2(620.0, 650.0, 260.0, 34.0),
		Rect2(1120.0, 560.0, 36.0, 220.0),
		Rect2(1340.0, 300.0, 160.0, 34.0),
	]

func _overlaps_key_point(rect: Rect2) -> bool:
	var key_points: Array[Vector2] = [
		Vector2(620.0, 170.0),
		Vector2(1040.0, 760.0),
		Vector2(1320.0, 360.0),
		Vector2(760.0, 650.0),
	]
	for point in key_points:
		if rect.grow(26.0).has_point(point):
			return true
	return false

func set_power_node_fixed(index: int) -> void:
	fixed_power_nodes[index] = true
	queue_redraw()

func set_safehouse_discovered(position: Vector2) -> void:
	safehouse_known = true
	safehouse_position = position
	queue_redraw()

func _add_obstacle(rect: Rect2) -> void:
	obstacle_rects.append(rect)
	var wall: Wall = Wall.new()
	add_child(wall)
	wall.setup(rect, obstacle_rects.size())

func _draw() -> void:
	var floor_rect := Rect2(0.0, 0.0, 1680.0, 1080.0)
	draw_rect(floor_rect, Color(0.07, 0.06, 0.075, 1.0), true)
	for corridor_rect in corridor_rects:
		draw_rect(corridor_rect, Color(0.13, 0.10, 0.12, 0.66), true)
		draw_rect(corridor_rect, Color(0.26, 0.19, 0.22, 0.45), false, 1.0)
	for room_rect in room_rects:
		draw_rect(room_rect, Color(0.10, 0.075, 0.085, 0.78), true)
		draw_rect(room_rect, Color(0.22, 0.15, 0.18, 0.65), false, 2.0)
	var grid_color := Color(0.22, 0.17, 0.2, 0.28)
	for x in range(0, 1681, 48):
		draw_line(Vector2(x, 0.0), Vector2(x, 1080.0), grid_color, 1.0)
	for y in range(0, 1081, 48):
		draw_line(Vector2(0.0, y), Vector2(1680.0, y), grid_color, 1.0)
	var power_positions: Array[Vector2] = [Vector2(620.0, 170.0), Vector2(1040.0, 760.0), Vector2(1320.0, 360.0)]
	for index in power_positions.size():
		var power_position: Vector2 = power_positions[index]
		var restored: bool = fixed_power_nodes.has(index)
		draw_circle(power_position, 118.0 if restored else 84.0, Color(0.05, 0.55, 0.52, 0.11 if restored else 0.025))
		draw_circle(power_position, 62.0, Color(0.12, 0.8, 0.7, 0.09 if restored else 0.02))
	if safehouse_known:
		draw_circle(safehouse_position, 16.0, Color(0.35, 0.95, 0.75, 0.18))
		draw_arc(safehouse_position, 22.0, 0.0, TAU, 32, Color(0.35, 0.95, 0.75, 0.72), 2.0)
