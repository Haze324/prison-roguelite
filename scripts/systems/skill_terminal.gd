@tool
class_name SkillTerminal
extends Node2D

const SKILLS: Array[String] = ["Quick Hands", "Silent Step", "Iron Will", "Field Medic"]
const DRAW_INTERVAL: float = 0.08
const EDGE: Color = Color("B980E8")
const PANEL: Color = Color("10171D")

var player: Player
var _player_nearby: bool = false
var _pulse_time: float = 0.0
var _draw_accumulator: float = 0.0

func setup(target: Player) -> void:
	player = target
	queue_redraw()

func _process(delta: float) -> void:
	if Engine.is_editor_hint():
		queue_redraw()
		return
	_pulse_time += delta
	_draw_accumulator += delta
	var nearby: bool = player != null and is_instance_valid(player) and global_position.distance_to(player.global_position) <= 48.0
	if nearby != _player_nearby:
		_player_nearby = nearby
		queue_redraw()
	if nearby and Input.is_action_just_pressed("interact"):
		for skill_name in SKILLS:
			if not MetaProgression.unlocked_skills.has(skill_name):
				if MetaProgression.unlock_skill(skill_name):
					EventBus.consumable_used.emit("Skill unlocked: " + _skill_display_name(skill_name))
				else:
					EventBus.consumable_used.emit("Skill console: 1 skill point required")
				return
		EventBus.consumable_used.emit("All four skills are already unlocked")
		queue_redraw()
	if _draw_accumulator >= DRAW_INTERVAL:
		_draw_accumulator = 0.0
		queue_redraw()

func _draw() -> void:
	var pulse: float = (sin(_pulse_time * 2.6) + 1.0) * 0.5
	# Compact wall terminal: dark chassis, inset display and service lights.
	_draw_ellipse(Vector2(0.0, 25.0), Vector2(27.0, 7.0), Color(0.01, 0.015, 0.02, 0.62))
	draw_rect(Rect2(-28.0, -31.0, 56.0, 58.0), Color("05090C"), true)
	draw_rect(Rect2(-25.0, -28.0, 50.0, 52.0), PANEL, true)
	draw_rect(Rect2(-25.0, -28.0, 50.0, 52.0), EDGE, false, 2.0)
	draw_line(Vector2(-20.0, -20.0), Vector2(20.0, -20.0), Color("405058"), 1.0)
	draw_rect(Rect2(-16.0, -13.0, 32.0, 22.0), Color("091116"), true)
	draw_rect(Rect2(-16.0, -13.0, 32.0, 22.0), Color(EDGE, 0.72), false, 1.0)
	draw_circle(Vector2(0.0, -2.0), 7.0, Color(EDGE, 0.18 + pulse * 0.1))
	draw_circle(Vector2(0.0, -2.0), 4.0, Color(EDGE, 0.9))
	draw_line(Vector2(-11.0, 15.0), Vector2(11.0, 15.0), Color(EDGE, 0.55), 2.0)
	for lamp_index in 3:
		draw_circle(Vector2(-9.0 + lamp_index * 9.0, 21.0), 1.8, EDGE if lamp_index == 0 else Color("5B4668"))
	if _player_nearby:
		draw_string(ThemeDB.fallback_font, Vector2(-39.0, -40.0), "SKILL CONSOLE", HORIZONTAL_ALIGNMENT_LEFT, -1.0, 10, EDGE)
		draw_string(ThemeDB.fallback_font, Vector2(-36.0, 43.0), "E  UNLOCK", HORIZONTAL_ALIGNMENT_LEFT, -1.0, 10, Color("E8F0E9"))

func _draw_ellipse(center: Vector2, radius: Vector2, color: Color) -> void:
	var points: PackedVector2Array = PackedVector2Array()
	for index in 24:
		var angle: float = TAU * float(index) / 24.0
		points.append(center + Vector2(cos(angle) * radius.x, sin(angle) * radius.y))
	draw_colored_polygon(points, color)

func _skill_display_name(skill_name: String) -> String:
	return skill_name
