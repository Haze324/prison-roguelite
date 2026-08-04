class_name NoiseMeter
extends Control

## 八段式噪声仪表：像无线电信号一样逐段变高，并按危险区间变色。

@export var value: float = 0.0
@export var maximum: float = 200.0
@export var bar_count: int = 8

func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	queue_redraw()

func set_value(noise_value: float) -> void:
	value = clampf(noise_value, 0.0, maximum)
	queue_redraw()

func _draw() -> void:
	if bar_count <= 0 or size.x <= 0.0 or size.y <= 0.0:
		return
	var step: float = size.x / float(bar_count)
	var active_bars: int = clampi(ceili(value / maxf(maximum / float(bar_count), 1.0)), 0, bar_count)
	for index in bar_count:
		var ratio: float = float(index + 1) / float(bar_count)
		var bar_height: float = lerpf(7.0, size.y - 2.0, ratio)
		var bar_rect: Rect2 = Rect2(Vector2(float(index) * step + 2.0, size.y - bar_height), Vector2(maxf(step - 5.0, 4.0), bar_height))
		var accent: Color = Color("61E4C0") if ratio <= 0.375 else Color("E7B455") if ratio <= 0.75 else Color("E56568")
		var active: bool = index < active_bars
		draw_rect(bar_rect, Color(accent, 0.9 if active else 0.1), true)
		draw_rect(bar_rect, Color(accent, 0.95 if active else 0.28), false, 1.0)
	draw_line(Vector2(0.0, size.y - 0.5), Vector2(size.x, size.y - 0.5), Color("5A7475"), 1.0)
