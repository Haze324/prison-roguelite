class_name ExitGate
extends Node2D

@export var interaction_radius: float = 48.0

const DRAW_INTERVAL: float = 0.10
const COLOR_LOCKED: Color = Color("66727B")
const COLOR_READY: Color = Color("55E6C1")

var player: Player
var available: bool = false
var used: bool = false
var _pulse_time: float = 0.0
var _draw_accumulator: float = 0.0
var _player_nearby: bool = false

func setup(target: Player) -> void:
	player = target
	add_to_group("exit_gate")
	queue_redraw()

func set_available(value: bool) -> void:
	if available == value:
		return
	available = value
	queue_redraw()

func _process(delta: float) -> void:
	_draw_accumulator += delta
	_pulse_time += delta
	var nearby: bool = player != null and is_instance_valid(player) and global_position.distance_to(player.global_position) <= interaction_radius
	if nearby != _player_nearby:
		_player_nearby = nearby
		queue_redraw()
	if available and not used and nearby and Input.is_action_just_pressed("interact"):
		used = true
		EventBus.extraction_available.emit()
		EventBus.run_completed.emit(true, 0, 0)
		queue_redraw()
	if available and _draw_accumulator >= DRAW_INTERVAL:
		_draw_accumulator = 0.0
		queue_redraw()

func _draw() -> void:
	var edge: Color = COLOR_READY if available else COLOR_LOCKED
	var pulse: float = (sin(_pulse_time * 2.8) + 1.0) * 0.5
	# Heavy frame, recessed gate and access reader; this is deliberately world-space, not Paper UI.
	draw_rect(Rect2(-43.0, -58.0, 86.0, 116.0), Color("05080A"), true)
	draw_rect(Rect2(-39.0, -54.0, 78.0, 108.0), Color("172126"), true)
	draw_rect(Rect2(-35.0, -50.0, 70.0, 100.0), Color("070B0E"), true)
	draw_rect(Rect2(-35.0, -50.0, 70.0, 100.0), edge, false, 2.0)
	draw_line(Vector2(-34.0, -34.0), Vector2(34.0, -34.0), Color("34464C"), 1.0)
	draw_line(Vector2(-34.0, 34.0), Vector2(34.0, 34.0), Color("34464C"), 1.0)
	for line_index in 5:
		var y: float = -20.0 + line_index * 10.0
		var line_color: Color = Color(edge, 0.35 + pulse * 0.25) if available else Color("26343A")
		draw_line(Vector2(-24.0, y), Vector2(24.0, y), line_color, 2.0)
	# Top warning lamps and a readable access panel.
	draw_circle(Vector2(-19.0, -43.0), 3.0, edge)
	draw_circle(Vector2(-9.0, -43.0), 3.0, edge if available else Color("442D2D"))
	draw_circle(Vector2(19.0, -43.0), 3.0, edge if available else Color("442D2D"))
	draw_rect(Rect2(-15.0, 39.0, 30.0, 8.0), Color("0B1114"), true)
	draw_rect(Rect2(-15.0, 39.0, 30.0, 8.0), edge, false, 1.0)
	draw_rect(Rect2(-10.0, 41.0, 20.0, 4.0), Color(edge, 0.75 if available else 0.25), true)
	if _player_nearby:
		var title: String = "EXIT  READY" if available else "EXIT  LOCKED"
		var action_text: String = "E  EXTRACT" if available and not used else "POWER REQUIRED"
		draw_string(ThemeDB.fallback_font, Vector2(-47.0, -67.0), title, HORIZONTAL_ALIGNMENT_LEFT, -1.0, 10, edge)
		draw_string(ThemeDB.fallback_font, Vector2(-52.0, 69.0), action_text, HORIZONTAL_ALIGNMENT_LEFT, -1.0, 10, edge)
