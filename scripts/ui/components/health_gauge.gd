class_name HealthGauge
extends Control

## 清晰的动态生命槽：实心生命、延迟损伤尾迹和高光边缘分层显示。

@export var value: float = 100.0
@export var maximum: float = 100.0
@export var fill_color: Color = Color("E56568")

var _visible_ratio: float = 1.0
var _trail_ratio: float = 1.0

func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	_visible_ratio = _ratio()
	_trail_ratio = _visible_ratio
	queue_redraw()

func set_value(current: float, maximum_value: float) -> void:
	value = current
	maximum = maximum_value
	var next_ratio: float = _ratio()
	if next_ratio > _visible_ratio:
		_visible_ratio = next_ratio
	if next_ratio > _trail_ratio:
		_trail_ratio = next_ratio
	queue_redraw()

func _process(delta: float) -> void:
	var target_ratio: float = _ratio()
	_visible_ratio = move_toward(_visible_ratio, target_ratio, delta * 6.0)
	_trail_ratio = move_toward(_trail_ratio, target_ratio, delta * 1.8)
	queue_redraw()

func _ratio() -> float:
	return clampf(value / maxf(maximum, 1.0), 0.0, 1.0)

func _draw() -> void:
	var gauge: Rect2 = Rect2(Vector2.ZERO, size)
	if gauge.size.x <= 0.0 or gauge.size.y <= 0.0:
		return
	draw_rect(gauge.grow(3.0), Color(0.0, 0.0, 0.0, 0.7), true)
	draw_rect(gauge, Color("17252A"), true)
	var trail: Rect2 = Rect2(gauge.position, Vector2(gauge.size.x * _trail_ratio, gauge.size.y))
	if trail.size.x > 0.0:
		draw_rect(trail, Color("8A3F4A"), true)
	var fill: Rect2 = Rect2(gauge.position, Vector2(gauge.size.x * _visible_ratio, gauge.size.y))
	if fill.size.x > 0.0:
		draw_rect(fill, fill_color, true)
		draw_line(fill.position + Vector2(2.0, 2.0), Vector2(fill.end.x - 2.0, fill.position.y + 2.0), Color("FFB3A7"), 1.0)
		draw_line(fill.position + Vector2(2.0, fill.end.y - 2.0), Vector2(fill.end.x - 2.0, fill.end.y - 2.0), Color(0.45, 0.08, 0.12, 0.55), 1.0)
	draw_rect(gauge, Color("E9B4A5"), false, 1.0)
