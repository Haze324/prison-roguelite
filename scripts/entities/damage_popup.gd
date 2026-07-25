class_name DamagePopup
extends Node2D

var amount: float = 0.0
var tint: Color = Color.WHITE
var lifetime: float = 0.75
var rise_speed: float = 28.0

func setup(damage_amount: float, world_position: Vector2, popup_tint: Color) -> void:
	amount = damage_amount
	global_position = world_position + Vector2(0.0, -28.0)
	tint = popup_tint
	lifetime = 0.75
	queue_redraw()

func _process(delta: float) -> void:
	lifetime -= delta
	position.y -= rise_speed * delta
	queue_redraw()
	if lifetime <= 0.0:
		queue_free()

func _draw() -> void:
	var alpha: float = clampf(lifetime / 0.75, 0.0, 1.0)
	var text: String = "-%d" % maxi(1, roundi(amount))
	var font: Font = ThemeDB.fallback_font
	draw_string(font, Vector2(-32.0, 2.0), text, HORIZONTAL_ALIGNMENT_CENTER, 64.0, 16, Color(0.02, 0.02, 0.03, 0.75 * alpha))
	draw_string(font, Vector2(-32.0, 0.0), text, HORIZONTAL_ALIGNMENT_CENTER, 64.0, 16, Color(tint, alpha))
