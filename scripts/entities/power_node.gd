class_name PowerNode
extends Node2D

## Industrial power relay used by the run objective.
## The node owns only world-space feedback; HUD objective text stays in DemoHUD.
@export var interaction_radius: float = 42.0
@export var repair_duration: float = 1.0

const DRAW_INTERVAL: float = 0.08
const PANEL_SIZE: Vector2 = Vector2(44.0, 58.0)
const COLOR_IDLE: Color = Color("F4B942")
const COLOR_ACTIVE: Color = Color("57E4C7")
const COLOR_PANEL: Color = Color("101A1E")
const COLOR_PANEL_DARK: Color = Color("071014")

var node_index: int = 0
var player: Player
var fixed: bool = false
var fixing: bool = false
var fix_remaining: float = 0.0
var _pulse_time: float = 0.0
var _draw_accumulator: float = 0.0
var _player_nearby: bool = false
var _last_fixing: bool = false

func _ready() -> void:
	add_to_group("power_nodes")
	queue_redraw()

func setup(index: int, target: Player) -> void:
	node_index = index
	player = target
	queue_redraw()

func _process(delta: float) -> void:
	_draw_accumulator += delta
	_pulse_time += delta
	var nearby: bool = player != null and is_instance_valid(player) and global_position.distance_to(player.global_position) <= interaction_radius
	if nearby != _player_nearby:
		_player_nearby = nearby
		queue_redraw()
	if not fixed and player != null and is_instance_valid(player):
		if nearby and not fixing and Input.is_action_just_pressed("interact"):
			fixing = true
			fix_remaining = repair_duration
		if fixing:
			if not nearby or not Input.is_action_pressed("interact"):
				fixing = false
				fix_remaining = 0.0
			elif fix_remaining > 0.0:
				fix_remaining = maxf(fix_remaining - delta, 0.0)
				if fix_remaining <= 0.0:
					fixing = false
					fixed = true
					EventBus.power_node_fixed.emit(self, 0, 0)
	if fixing != _last_fixing:
		_last_fixing = fixing
		queue_redraw()
	if _draw_accumulator >= DRAW_INTERVAL and (not fixed or _player_nearby or fixing):
		_draw_accumulator = 0.0
		queue_redraw()

func _draw() -> void:
	var edge: Color = COLOR_ACTIVE if fixed else COLOR_IDLE
	var glow: Color = Color(edge, 0.10 if fixed else 0.06)
	var pulse: float = (sin(_pulse_time * 2.4) + 1.0) * 0.5
	var panel: Rect2 = Rect2(-PANEL_SIZE * 0.5, PANEL_SIZE)
	# Ground plate and rear cable housing establish a readable industrial silhouette.
	_draw_ellipse(Vector2(0.0, 31.0), Vector2(31.0, 8.0), Color(0.01, 0.015, 0.018, 0.62))
	draw_rect(Rect2(-27.0, 22.0, 54.0, 10.0), Color("080D10"), true)
	draw_rect(Rect2(-27.0, 22.0, 54.0, 10.0), Color("31464A"), false, 1.0)
	draw_rect(Rect2(-24.0, -31.0, 48.0, 59.0), Color("05090C"), true)
	draw_rect(Rect2(-22.0, -29.0, 44.0, 55.0), COLOR_PANEL, true)
	draw_rect(panel, edge, false, 2.0)
	draw_line(Vector2(-19.0, -20.0), Vector2(19.0, -20.0), Color("3B5357"), 1.0)
	draw_line(Vector2(-19.0, 14.0), Vector2(19.0, 14.0), Color("26393D"), 1.0)
	for bolt_x in [-17.0, 17.0]:
		draw_circle(Vector2(bolt_x, -24.0), 1.8, Color("8A9B91"))
		draw_circle(Vector2(bolt_x, 21.0), 1.8, Color("8A9B91"))
	# Reactor lens and four status lamps.
	draw_circle(Vector2(0.0, -4.0), 15.0, Color(edge, 0.12 + pulse * 0.05))
	draw_arc(Vector2(0.0, -4.0), 14.0, 0.0, TAU, 24, edge, 1.5)
	draw_circle(Vector2(0.0, -4.0), 8.0, Color(edge, 0.78))
	draw_circle(Vector2(0.0, -4.0), 4.0, Color("E9FFF7") if fixed else Color("FFF0BD"))
	for lamp_index in 4:
		var lamp_color: Color = edge if fixed or lamp_index == 0 else Color("6E4F2C")
		draw_circle(Vector2(-12.0 + lamp_index * 8.0, 18.0), 2.0, lamp_color)
	if _player_nearby:
		var title: String = "POWER RELAY %02d" % (node_index + 1)
		var action_text: String = "ONLINE" if fixed else "E  REPAIR"
		if fixing:
			action_text = "REPAIR  %02d%%" % int((1.0 - fix_remaining / repair_duration) * 100.0)
		draw_string(ThemeDB.fallback_font, Vector2(-50.0, -43.0), title, HORIZONTAL_ALIGNMENT_LEFT, -1.0, 10, edge)
		draw_string(ThemeDB.fallback_font, Vector2(-46.0, 49.0), action_text, HORIZONTAL_ALIGNMENT_LEFT, -1.0, 10, edge)
	if fixing:
		var progress: float = 1.0 - clampf(fix_remaining / repair_duration, 0.0, 1.0)
		draw_arc(Vector2.ZERO, 35.0, -PI * 0.5, -PI * 0.5 + TAU * progress, 32, Color("FFD66E"), 3.0)

func _draw_ellipse(center: Vector2, radius: Vector2, color: Color) -> void:
	var points: PackedVector2Array = PackedVector2Array()
	for index in 24:
		var angle: float = TAU * float(index) / 24.0
		points.append(center + Vector2(cos(angle) * radius.x, sin(angle) * radius.y))
	draw_colored_polygon(points, color)
