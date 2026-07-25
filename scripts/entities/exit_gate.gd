class_name ExitGate
extends Node2D

var player: Player
var available: bool = false
var used: bool = false

func setup(target: Player) -> void:
    player = target
    add_to_group("exit_gate")
    queue_redraw()

func set_available(value: bool) -> void:
    available = value
    queue_redraw()

func _process(_delta: float) -> void:
    if available and not used and player != null and global_position.distance_to(player.global_position) <= 48.0 and Input.is_action_just_pressed("interact"):
        used = true
        EventBus.extraction_available.emit()
        EventBus.run_completed.emit(true, 0, 0)

func _draw() -> void:
    var edge := Color(0.3, 0.95, 0.75, 1.0) if available else Color(0.35, 0.4, 0.45, 1.0)
    draw_rect(Rect2(-32.0, -46.0, 64.0, 92.0), Color(0.04, 0.05, 0.07, 0.95), true)
    draw_rect(Rect2(-32.0, -46.0, 64.0, 92.0), edge, false, 3.0)
    draw_line(Vector2(-18.0, 30.0), Vector2(18.0, 30.0), edge, 3.0)
    draw_string(ThemeDB.fallback_font, Vector2(-36.0, -56.0), "撤离" if available else "未解锁", HORIZONTAL_ALIGNMENT_LEFT, -1.0, 12, edge)
