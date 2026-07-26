class_name MapPlaceable
extends StaticBody2D

enum Kind { ROOM, WALL, LIGHT, DARK, LASER, POWER, PICKUP }

var kind: int = Kind.WALL
var size: Vector2 = Vector2(96.0, 48.0)
var variant: int = 0
var _shape: CollisionShape2D

func setup(place_kind: int, rect: Rect2, style_variant: int = 0) -> void:
	kind = place_kind
	position = rect.position + rect.size * 0.5
	size = rect.size
	variant = style_variant
	_collision_enabled(kind == Kind.WALL)
	queue_redraw()

func _collision_enabled(enabled: bool) -> void:
	if not enabled:
		if _shape != null:
			_shape.disabled = true
		return
	if _shape == null:
		_shape = CollisionShape2D.new()
		add_child(_shape)
	_shape.disabled = false
	var rectangle := RectangleShape2D.new()
	rectangle.size = size
	_shape.shape = rectangle
	collision_layer = 1
	collision_mask = 1

func take_damage(_amount: float) -> void:
	if kind == Kind.POWER:
		variant += 1
		queue_redraw()

func _draw() -> void:
	var rect := Rect2(-size * 0.5, size)
	match kind:
		Kind.ROOM:
			draw_rect(rect, Color(0.12, 0.09, 0.13, 0.28), true)
			draw_rect(rect, Color(0.54, 0.34, 0.42, 0.7), false, 2.0)
			_draw_corner_marks(rect, Color(0.82, 0.57, 0.58, 0.8))
		Kind.WALL:
			_draw_wall(rect)
		Kind.LIGHT:
			draw_circle(Vector2.ZERO, maxf(size.x, size.y) * 0.5, Color(1.0, 0.75, 0.32, 0.08))
			draw_circle(Vector2.ZERO, 18.0, Color(1.0, 0.82, 0.42, 0.85))
			draw_arc(Vector2.ZERO, maxf(size.x, size.y) * 0.5, 0.0, TAU, 32, Color(1.0, 0.68, 0.28, 0.55), 2.0)
		Kind.DARK:
			draw_circle(Vector2.ZERO, maxf(size.x, size.y) * 0.5, Color(0.01, 0.015, 0.03, 0.72))
			draw_arc(Vector2.ZERO, maxf(size.x, size.y) * 0.5, 0.0, TAU, 32, Color(0.2, 0.25, 0.38, 0.8), 2.0)
		Kind.LASER:
			draw_rect(rect, Color(0.16, 0.04, 0.08, 0.92), true)
			draw_line(Vector2(rect.position.x, 0.0), Vector2(rect.end.x, 0.0), Color(1.0, 0.2, 0.38, 1.0), 5.0)
			draw_line(Vector2(rect.position.x, 0.0), Vector2(rect.end.x, 0.0), Color(1.0, 0.85, 0.9, 0.9), 1.0)
		Kind.POWER:
			draw_circle(Vector2.ZERO, 22.0, Color(0.08, 0.75, 0.66, 0.25))
			draw_circle(Vector2.ZERO, 12.0, Color(0.2, 0.95, 0.82, 0.9))
			draw_line(Vector2(-7, 0), Vector2(7, 0), Color.WHITE, 2.0)
			draw_line(Vector2(0, -7), Vector2(0, 7), Color.WHITE, 2.0)
		Kind.PICKUP:
			draw_circle(Vector2.ZERO, 14.0, Color(0.78, 0.45, 0.95, 0.9))
			draw_circle(Vector2.ZERO, 7.0, Color(0.16, 0.08, 0.24, 1.0))

func _draw_wall(rect: Rect2) -> void:
	var colors: Array[Color] = [Color("34454B"), Color("3D414D"), Color("4A3D42")]
	var accent: Color = [Color("6C8A86"), Color("7D7886"), Color("8C6B67")][variant % 3]
	draw_rect(rect.grow(5.0), Color(0.0, 0.0, 0.0, 0.45), true)
	draw_rect(rect, colors[variant % 3], true)
	draw_rect(rect, Color("111A20"), false, 2.0)
	draw_line(rect.position + Vector2(3, 4), Vector2(rect.end.x - 3, rect.position.y + 4), accent, 2.0)
	for x in range(int(rect.position.x + 18), int(rect.end.x), 36):
		draw_line(Vector2(x, rect.position.y + 5), Vector2(x - 8, rect.end.y - 5), Color("1A252B"), 1.0)

func _draw_corner_marks(rect: Rect2, color: Color) -> void:
	for corner in [rect.position, Vector2(rect.end.x, rect.position.y), rect.end, Vector2(rect.position.x, rect.end.y)]:
		draw_circle(corner, 4.0, color)
