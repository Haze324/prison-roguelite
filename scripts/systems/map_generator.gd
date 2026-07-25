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
	for rect in obstacle_rects:
		draw_rect(rect, Color(0.22, 0.17, 0.2, 0.96), true)
		draw_rect(rect, Color(0.48, 0.31, 0.36, 0.9), false, 2.0)
