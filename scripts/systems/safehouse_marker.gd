class_name SafehouseMarker
extends Node2D

@export var size: Vector2 = Vector2(180.0, 140.0)

func _ready() -> void:
    queue_redraw()

func _draw() -> void:
    var rect := Rect2(-size * 0.5, size)
    draw_rect(rect, Color(0.12, 0.32, 0.28, 0.3), true)
    draw_rect(rect, Color(0.35, 0.9, 0.7, 0.8), false, 3.0)
    draw_line(Vector2(-size.x * 0.5, 0.0), Vector2(size.x * 0.5, 0.0), Color(0.35, 0.9, 0.7, 0.25), 1.0)
    draw_line(Vector2(0.0, -size.y * 0.5), Vector2(0.0, size.y * 0.5), Color(0.35, 0.9, 0.7, 0.25), 1.0)
