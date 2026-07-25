class_name MapGenerator
extends Node2D

@export var map_seed: int = 0

var obstacle_rects: Array[Rect2] = []

func generate(new_seed: int = 0) -> void:
	map_seed = new_seed if new_seed != 0 else randi()
	for child in get_children():
		child.queue_free()
	obstacle_rects.clear()
	var candidates: Array[Rect2] = [
		Rect2(540.0, 170.0, 180.0, 34.0),
		Rect2(820.0, 300.0, 36.0, 220.0),
		Rect2(1040.0, 150.0, 220.0, 34.0),
		Rect2(620.0, 650.0, 260.0, 34.0),
		Rect2(1120.0, 560.0, 36.0, 220.0),
		Rect2(1340.0, 300.0, 160.0, 34.0),
	]
	var rng := RandomNumberGenerator.new()
	rng.seed = map_seed
	for candidate in candidates:
		if rng.randf() < 0.15:
			continue
		_add_obstacle(candidate)
	queue_redraw()
	EventBus.map_generated.emit(map_seed, 1)

func _add_obstacle(rect: Rect2) -> void:
	obstacle_rects.append(rect)
	var body := StaticBody2D.new()
	body.position = rect.position + rect.size * 0.5
	body.collision_layer = 1
	body.collision_mask = 1
	var shape := CollisionShape2D.new()
	var rectangle := RectangleShape2D.new()
	rectangle.size = rect.size
	shape.shape = rectangle
	body.add_child(shape)
	add_child(body)

func _draw() -> void:
	var floor_rect := Rect2(0.0, 0.0, 1680.0, 1080.0)
	draw_rect(floor_rect, Color(0.07, 0.06, 0.075, 1.0), true)
	var room_rects: Array[Rect2] = [
		Rect2(36.0, 50.0, 390.0, 260.0),
		Rect2(470.0, 50.0, 420.0, 250.0),
		Rect2(940.0, 50.0, 370.0, 260.0),
		Rect2(80.0, 420.0, 430.0, 270.0),
		Rect2(560.0, 420.0, 430.0, 260.0),
		Rect2(1080.0, 430.0, 430.0, 300.0),
	]
	for room_rect in room_rects:
		draw_rect(room_rect, Color(0.10, 0.075, 0.085, 0.78), true)
		draw_rect(room_rect, Color(0.22, 0.15, 0.18, 0.65), false, 2.0)
	var grid_color := Color(0.22, 0.17, 0.2, 0.28)
	for x in range(0, 1681, 48):
		draw_line(Vector2(x, 0.0), Vector2(x, 1080.0), grid_color, 1.0)
	for y in range(0, 1081, 48):
		draw_line(Vector2(0.0, y), Vector2(1680.0, y), grid_color, 1.0)
	var power_positions: Array[Vector2] = [Vector2(620.0, 170.0), Vector2(1040.0, 760.0), Vector2(1320.0, 360.0)]
	for power_position in power_positions:
		draw_circle(power_position, 118.0, Color(0.05, 0.55, 0.52, 0.055))
		draw_circle(power_position, 62.0, Color(0.12, 0.8, 0.7, 0.045))
	for rect in obstacle_rects:
		draw_rect(rect.grow(5.0), Color(0.035, 0.025, 0.035, 1.0), true)
		draw_rect(rect, Color(0.27, 0.19, 0.23, 1.0), true)
		draw_rect(rect, Color(0.62, 0.38, 0.43, 0.95), false, 2.0)
		draw_line(rect.position + Vector2(4.0, 6.0), Vector2(rect.end.x - 4.0, rect.position.y + 6.0), Color(0.78, 0.51, 0.45, 0.45), 2.0)
		draw_circle(rect.position + Vector2(8.0, 8.0), 2.0, Color(0.88, 0.63, 0.42, 0.8))
		draw_circle(rect.end - Vector2(8.0, 8.0), 2.0, Color(0.88, 0.63, 0.42, 0.8))
