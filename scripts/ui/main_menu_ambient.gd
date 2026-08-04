class_name MainMenuAmbient
extends Control

## 动态封面氛围层：只负责灯光、暗角和轻微环境呼吸，不承载交互文本。

var _time: float = 0.0

func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	queue_redraw()

func _process(delta: float) -> void:
	_time += delta
	queue_redraw()

func _draw() -> void:
	var screen: Vector2 = size
	if screen.x <= 0.0 or screen.y <= 0.0:
		return
	# 左侧控制台保持可读，右侧场景保留空间纵深。
	draw_rect(Rect2(0.0, 0.0, screen.x * 0.54, screen.y), Color(0.01, 0.015, 0.016, 0.18), true)
	draw_rect(Rect2(0.0, 0.0, screen.x, 26.0), Color(0.0, 0.0, 0.0, 0.28), true)
	draw_rect(Rect2(0.0, screen.y - 24.0, screen.x, 24.0), Color(0.0, 0.0, 0.0, 0.34), true)

	var red_pulse: float = 0.72 + sin(_time * 1.4) * 0.18
	var cyan_pulse: float = 0.74 + sin(_time * 0.72 + 1.0) * 0.10
	_draw_halo(Vector2(screen.x * 0.45, screen.y * 0.36), 105.0, Color("B84D45"), red_pulse * 0.19)
	_draw_halo(Vector2(screen.x * 0.80, screen.y * 0.50), 170.0, Color("28BBA5"), cyan_pulse * 0.16)

	# 轻微扫描光，保持节奏感但不遮挡文字。
	var scan_y: float = fmod(_time * 12.0, maxf(screen.y, 1.0))
	draw_rect(Rect2(screen.x * 0.58, scan_y, screen.x * 0.42, 1.0), Color("79D4BF", 0.045), true)

func _draw_halo(center: Vector2, radius: float, color: Color, strength: float) -> void:
	for index in range(6, 0, -1):
		var ratio: float = float(index) / 6.0
		var alpha: float = strength * (1.0 - ratio) * 0.85
		draw_circle(center, radius * ratio, Color(color, alpha))
