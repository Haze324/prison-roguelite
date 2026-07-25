class_name SafehouseMarker
extends Node2D

@export var size: Vector2 = Vector2(180.0, 140.0)
var player: Player

func _ready() -> void:
    add_to_group("safehouses")
    queue_redraw()

func contains_point(point: Vector2) -> bool:
    return Rect2(-size * 0.5, size).has_point(to_local(point))

func setup(target_player: Player) -> void:
    player = target_player
    queue_redraw()

func _process(_delta: float) -> void:
    queue_redraw()

func _draw() -> void:
    var rect := Rect2(-size * 0.5, size)
    var glow := Color(0.25, 0.9, 0.7, 0.18)
    var edge := Color(0.35, 0.95, 0.75, 0.95)
    draw_rect(rect, glow, true)
    draw_rect(rect, edge, false, 3.0)
    draw_rect(Rect2(-34.0, -22.0, 68.0, 54.0), Color(0.08, 0.2, 0.2, 0.9), true)
    draw_rect(Rect2(-34.0, -22.0, 68.0, 54.0), edge, false, 2.0)
    draw_rect(Rect2(-13.0, -8.0, 26.0, 40.0), Color(0.04, 0.08, 0.09, 1.0), true)
    draw_circle(Vector2(7.0, 12.0), 3.0, Color(0.95, 0.78, 0.3, 1.0))
    var nearby: bool = player != null and global_position.distance_to(player.global_position) <= 180.0
    if nearby:
        draw_string(ThemeDB.fallback_font, Vector2(-67.0, -52.0), "SAFEHOUSE", HORIZONTAL_ALIGNMENT_LEFT, -1.0, 14, edge)
        draw_string(ThemeDB.fallback_font, Vector2(-54.0, 58.0), "E: RESUPPLY", HORIZONTAL_ALIGNMENT_LEFT, -1.0, 10, Color(0.75, 0.9, 0.82, 1.0))
