class_name Wall
extends StaticBody2D

## 可碰撞实体墙：地图掩体、房间墙和安全屋边界统一使用此节点。
var size: Vector2 = Vector2(120.0, 32.0)
var wall_variant: int = 0
var _collision_shape: CollisionShape2D
var _light_occluder: LightOccluder2D

func setup(rect: Rect2, variant: int = 0) -> void:
    position = rect.position + rect.size * 0.5
    size = rect.size
    wall_variant = variant % 3
    collision_layer = 1
    collision_mask = 1
    z_index = 1
    _build_collision()
    _build_light_occluder()
    queue_redraw()

func _ready() -> void:
    add_to_group("实体墙")
    _build_collision()
    _build_light_occluder()
    queue_redraw()

func _build_collision() -> void:
    if _collision_shape == null:
        _collision_shape = CollisionShape2D.new()
        _collision_shape.name = "墙体碰撞"
        add_child(_collision_shape)
    var rectangle: RectangleShape2D = RectangleShape2D.new()
    rectangle.size = size
    _collision_shape.shape = rectangle

func _build_light_occluder() -> void:
    if _light_occluder == null:
        _light_occluder = LightOccluder2D.new()
        _light_occluder.name = "墙体遮光"
        add_child(_light_occluder)
    var polygon: OccluderPolygon2D = OccluderPolygon2D.new()
    polygon.polygon = PackedVector2Array([
        Vector2(-size.x * 0.5, -size.y * 0.5),
        Vector2(size.x * 0.5, -size.y * 0.5),
        Vector2(size.x * 0.5, size.y * 0.5),
        Vector2(-size.x * 0.5, size.y * 0.5),
    ])
    _light_occluder.occluder = polygon

func _draw() -> void:
    var rect: Rect2 = Rect2(-size * 0.5, size)
    var base_colors: Array[Color] = [Color("34454B"), Color("3D414D"), Color("4A3D42")]
    var mortar: Color = Color("1A252B")
    var highlight: Color = [Color("6C8A86"), Color("7D7886"), Color("8C6B67")][wall_variant]
    draw_rect(rect.grow(5.0), Color(0.0, 0.0, 0.0, 0.45), true)
    draw_rect(rect, base_colors[wall_variant], true)
    draw_rect(rect, Color("111A20"), false, 2.0)
    draw_line(rect.position + Vector2(3.0, 4.0), Vector2(rect.end.x - 3.0, rect.position.y + 4.0), highlight, 2.0)
    var brick_height: float = 16.0 if size.y >= 28.0 else 10.0
    var row: int = 0
    var y: float = rect.position.y + brick_height
    while y < rect.end.y:
        draw_line(Vector2(rect.position.x + 2.0, y), Vector2(rect.end.x - 2.0, y), mortar, 1.0)
        var offset: float = 0.0 if row % 2 == 0 else 18.0
        var x: float = rect.position.x + offset
        while x < rect.end.x:
            draw_line(Vector2(x, y - brick_height + 1.0), Vector2(x, y - 1.0), mortar, 1.0)
            x += 36.0
        y += brick_height
        row += 1
    draw_circle(rect.position + Vector2(8.0, 8.0), 2.5, highlight)
    draw_circle(rect.end - Vector2(8.0, 8.0), 2.5, highlight)
