class_name PowerNode
extends Node2D

var node_index: int = 0
var player: Player
var fixed: bool = false

func setup(index: int, target: Player) -> void:
    node_index = index
    player = target
    add_to_group("power_nodes")
    queue_redraw()

func _process(_delta: float) -> void:
    if not fixed and player != null and global_position.distance_to(player.global_position) <= 42.0 and Input.is_action_just_pressed("interact"):
        fixed = true
        EventBus.power_node_fixed.emit(self, 0, 0)
        queue_redraw()

func _draw() -> void:
    var edge := Color(0.95, 0.72, 0.3, 1.0) if not fixed else Color(0.35, 0.95, 0.72, 1.0)
    draw_rect(Rect2(-16.0, -22.0, 32.0, 44.0), Color(0.06, 0.08, 0.1, 0.95), true)
    draw_rect(Rect2(-16.0, -22.0, 32.0, 44.0), edge, false, 2.0)
    draw_circle(Vector2(0.0, -8.0), 6.0, edge)
    draw_string(ThemeDB.fallback_font, Vector2(-28.0, -32.0), "POWER %d" % (node_index + 1), HORIZONTAL_ALIGNMENT_LEFT, -1.0, 10, edge)
    draw_string(ThemeDB.fallback_font, Vector2(-26.0, 58.0), "FIXED" if fixed else "E: FIX", HORIZONTAL_ALIGNMENT_LEFT, -1.0, 10, edge)
