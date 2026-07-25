class_name PowerNode
extends Node2D

var node_index: int = 0
var player: Player
var fixed: bool = false
var fixing: bool = false
var fix_remaining: float = 0.0

func setup(index: int, target: Player) -> void:
    node_index = index
    player = target
    add_to_group("power_nodes")
    queue_redraw()

func _process(delta: float) -> void:
	queue_redraw()
	if fixed or player == null:
		return
	var nearby: bool = global_position.distance_to(player.global_position) <= 42.0
	if nearby and Input.is_action_just_pressed("interact"):
		fixing = true
		fix_remaining = 1.0
	if fixing:
		if not nearby or not Input.is_action_pressed("interact"):
			fixing = false
			fix_remaining = 0.0
			return
		fix_remaining = maxf(fix_remaining - delta, 0.0)
		if fix_remaining <= 0.0:
			fixing = false
			fixed = true
			EventBus.power_node_fixed.emit(self, 0, 0)

func _draw() -> void:
    var edge := Color(0.95, 0.72, 0.3, 1.0) if not fixed else Color(0.35, 0.95, 0.72, 1.0)
    draw_circle(Vector2(0.0, 18.0), 24.0, Color(0.01, 0.02, 0.025, 0.7))
    draw_rect(Rect2(-16.0, -22.0, 32.0, 44.0), Color(0.06, 0.08, 0.1, 0.95), true)
    draw_rect(Rect2(-16.0, -22.0, 32.0, 44.0), edge, false, 2.0)
    draw_circle(Vector2(0.0, -8.0), 6.0, edge)
	var nearby: bool = player != null and global_position.distance_to(player.global_position) <= 120.0
	if nearby:
		draw_string(ThemeDB.fallback_font, Vector2(-28.0, -32.0), "POWER %d" % (node_index + 1), HORIZONTAL_ALIGNMENT_LEFT, -1.0, 10, edge)
		var action_text: String = "FIXED" if fixed else "E: FIX"
		if fixing:
			action_text = "FIX %.1fs" % fix_remaining
		draw_string(ThemeDB.fallback_font, Vector2(-30.0, 58.0), action_text, HORIZONTAL_ALIGNMENT_LEFT, -1.0, 10, edge)
	if fixing:
		var progress: float = 1.0 - clampf(fix_remaining, 0.0, 1.0)
		draw_arc(Vector2.ZERO, 29.0, -PI * 0.5, -PI * 0.5 + TAU * progress, 24, Color(1.0, 0.84, 0.35, 1.0), 3.0)
