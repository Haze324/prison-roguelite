class_name FlashlightCone
extends Node2D

var direction: Vector2 = Vector2.RIGHT
var enabled: bool = true
var length: float = 240.0
var half_angle: float = 0.3

func set_direction(next_direction: Vector2) -> void:
    if next_direction.length_squared() > 0.001:
        direction = next_direction.normalized()
        rotation = direction.angle()
    queue_redraw()

func set_enabled(value: bool) -> void:
    enabled = value
    queue_redraw()

func _draw() -> void:
    if not enabled:
        return
    var near_color: Color = Color(1.0, 0.92, 0.6, 0.12)
    var far_color: Color = Color(1.0, 0.88, 0.45, 0.025)
    var points: PackedVector2Array = PackedVector2Array([
        Vector2.ZERO,
        Vector2.from_angle(-half_angle) * length,
        Vector2.from_angle(half_angle) * length,
    ])
    draw_colored_polygon(points, far_color)
    draw_arc(Vector2.ZERO, length, -half_angle, half_angle, 24, Color(1.0, 0.92, 0.58, 0.24), 1.5)
    draw_line(Vector2.ZERO, Vector2.from_angle(-half_angle) * length, Color(1.0, 0.92, 0.58, 0.16), 1.0)
    draw_line(Vector2.ZERO, Vector2.from_angle(half_angle) * length, Color(1.0, 0.92, 0.58, 0.16), 1.0)
    draw_circle(Vector2.from_angle(direction.angle() - rotation) * 34.0, 18.0, near_color)
    draw_line(Vector2.ZERO, Vector2.RIGHT * 76.0, Color(1.0, 0.95, 0.7, 0.2), 3.0)
