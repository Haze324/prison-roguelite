@tool
class_name RespawnPoint
extends Node2D

## Placeable checkpoint/rest station. It is not a safehouse or force field.
@export var point_id: int = 0
@export var interaction_radius: float = 56.0
@export var restore_supplies: bool = true

const DRAW_INTERVAL: float = 0.08

var player: Player
var activated: bool = false
var _player_nearby: bool = false
var _pulse_time: float = 0.0
var _draw_accumulator: float = 0.0

func _ready() -> void:
	add_to_group("respawn_points")
	queue_redraw()

func setup(target: Player) -> void:
	player = target
	queue_redraw()

func contains_point(point: Vector2) -> bool:
	return global_position.distance_to(point) <= interaction_radius

func _process(delta: float) -> void:
	if Engine.is_editor_hint():
		queue_redraw()
		return
	_pulse_time += delta
	_draw_accumulator += delta
	var nearby: bool = player != null and is_instance_valid(player) and contains_point(player.global_position)
	if nearby != _player_nearby:
		_player_nearby = nearby
		queue_redraw()
	if not nearby:
		return
	if Input.is_action_just_pressed("interact"):
		activated = true
		player.set_respawn_point(global_position)
		if restore_supplies:
			player.restore_at_respawn_point()
		else:
			EventBus.consumable_used.emit("Checkpoint activated")
		queue_redraw()
	if _draw_accumulator >= DRAW_INTERVAL:
		_draw_accumulator = 0.0
		queue_redraw()

func _draw() -> void:
	var accent: Color = Color("72E0C2") if activated else Color("53D9D0")
	var pulse: float = (sin(_pulse_time * 2.2) + 1.0) * 0.5
	# Checkpoint beacon: low plinth, vertical status core and no floating placeholder box.
	_draw_ellipse(Vector2(0.0, 25.0), Vector2(31.0, 8.0), Color(0.01, 0.015, 0.02, 0.62))
	draw_rect(Rect2(-31.0, 14.0, 62.0, 11.0), Color("071014"), true)
	draw_rect(Rect2(-31.0, 14.0, 62.0, 11.0), Color("3C6665"), false, 1.0)
	draw_rect(Rect2(-24.0, -28.0, 48.0, 45.0), Color("05090C"), true)
	draw_rect(Rect2(-21.0, -25.0, 42.0, 39.0), Color("102326"), true)
	draw_rect(Rect2(-21.0, -25.0, 42.0, 39.0), accent, false, 2.0)
	draw_line(Vector2(-16.0, -17.0), Vector2(16.0, -17.0), Color("40595B"), 1.0)
	draw_circle(Vector2(0.0, -2.0), 14.0, Color(accent, 0.11 + pulse * 0.05))
	draw_arc(Vector2(0.0, -2.0), 12.0, 0.0, TAU, 24, accent, 1.4)
	draw_circle(Vector2(0.0, -2.0), 7.0, accent)
	draw_line(Vector2(-10.0, -2.0), Vector2(10.0, -2.0), Color("071014"), 2.0)
	for lamp_index in 3:
		draw_circle(Vector2(-8.0 + lamp_index * 8.0, 9.0), 1.8, accent if activated else Color("335A5A"))
	if _player_nearby:
		draw_string(ThemeDB.fallback_font, Vector2(-43.0, -37.0), "CHECKPOINT", HORIZONTAL_ALIGNMENT_LEFT, -1.0, 10, accent)
		draw_string(ThemeDB.fallback_font, Vector2(-46.0, 42.0), "E  ACTIVATE", HORIZONTAL_ALIGNMENT_LEFT, -1.0, 10, Color("D7E7DD"))

func _draw_ellipse(center: Vector2, radius: Vector2, color: Color) -> void:
	var points: PackedVector2Array = PackedVector2Array()
	for index in 24:
		var angle: float = TAU * float(index) / 24.0
		points.append(center + Vector2(cos(angle) * radius.x, sin(angle) * radius.y))
	draw_colored_polygon(points, color)
