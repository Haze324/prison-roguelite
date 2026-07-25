class_name SafehouseMarker
extends Node2D

## 安全屋碰撞和可视区域大小。
@export var size: Vector2 = Vector2(180.0, 140.0)
## 安全屋在本局地图中的稳定编号。
@export var house_id: int = 1
var player: Player
var discovered: bool = false

func _ready() -> void:
    add_to_group("safehouses")
    _build_boundary_walls()
    queue_redraw()

func _build_boundary_walls() -> void:
    var thickness: float = 14.0
    var doorway: float = 52.0
    var wall_rects: Array[Rect2] = [
        Rect2(-size.x * 0.5, -size.y * 0.5, size.x, thickness),
        Rect2(-size.x * 0.5, -size.y * 0.5, thickness, size.y),
        Rect2(size.x * 0.5 - thickness, -size.y * 0.5, thickness, size.y),
        Rect2(-size.x * 0.5, size.y * 0.5 - thickness, (size.x - doorway) * 0.5, thickness),
        Rect2(doorway * 0.5, size.y * 0.5 - thickness, (size.x - doorway) * 0.5, thickness),
    ]
    for index in wall_rects.size():
        var wall: Wall = Wall.new()
        add_child(wall)
        wall.setup(wall_rects[index], index + 2)

func contains_point(point: Vector2) -> bool:
    return Rect2(-size * 0.5, size).has_point(to_local(point))

func setup(target_player: Player) -> void:
    player = target_player
    queue_redraw()

func _process(_delta: float) -> void:
    if not discovered and player != null and contains_point(player.global_position):
        discovered = true
        EventBus.safehouse_discovered.emit(house_id)
    queue_redraw()

func _draw() -> void:
    var rect := Rect2(-size * 0.5, size)
    var glow := Color(0.25, 0.9, 0.7, 0.18)
    var edge := Color(0.35, 0.95, 0.75, 0.95)
    draw_rect(rect, glow, true)
    draw_rect(rect, edge, false, 3.0)
    draw_rect(Rect2(-70.0, -48.0, 140.0, 88.0), Color(1.0, 0.62, 0.25, 0.08), true)
    draw_rect(Rect2(-34.0, -22.0, 68.0, 54.0), Color(0.08, 0.2, 0.2, 0.9), true)
    draw_rect(Rect2(-34.0, -22.0, 68.0, 54.0), edge, false, 2.0)
    draw_rect(Rect2(-13.0, -8.0, 26.0, 40.0), Color(0.04, 0.08, 0.09, 1.0), true)
    draw_circle(Vector2(7.0, 12.0), 3.0, Color(0.95, 0.78, 0.3, 1.0))
    draw_arc(Vector2.ZERO, 104.0, 0.0, TAU, 48, Color(0.35, 0.95, 0.75, 0.24), 2.0)
    var nearby: bool = player != null and global_position.distance_to(player.global_position) <= 180.0
    if nearby:
        draw_string(ThemeDB.fallback_font, Vector2(-48.0, -52.0), "安全屋", HORIZONTAL_ALIGNMENT_LEFT, -1.0, 14, edge)
        draw_string(ThemeDB.fallback_font, Vector2(-46.0, 58.0), "E：补给整备", HORIZONTAL_ALIGNMENT_LEFT, -1.0, 10, Color(0.75, 0.9, 0.82, 1.0))
