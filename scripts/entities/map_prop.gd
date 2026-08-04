@tool
class_name MapProp
extends StaticBody2D

## Legacy placeholder prop. Final map props should be authored in the TileMap.
@export_enum("crate", "shelf", "generator", "console", "pillar", "debris") var prop_type: String = "crate":
	set(value):
		prop_type = value
		queue_redraw()

## Occupied footprint used by the legacy placeholder collision.
@export var size: Vector2 = Vector2(72.0, 48.0):
	set(value):
		size = value
		_rebuild_collision()
		queue_redraw()

## Whether this legacy placeholder blocks actors.
@export var solid: bool = true:
	set(value):
		solid = value
		_rebuild_collision()

@export var prop_color: Color = Color("3A4648")

var _shape: CollisionShape2D

func _ready() -> void:
	if _disabled_by_legacy_architecture():
		_disable_legacy_prop()
		return
	add_to_group("map_props")
	_rebuild_collision()
	queue_redraw()

func _process(_delta: float) -> void:
	# Keep the editor in sync if the parent metadata is changed while editing.
	if _disabled_by_legacy_architecture():
		_disable_legacy_prop()

func _disabled_by_legacy_architecture() -> bool:
	var parent_node: Node = get_parent()
	while parent_node != null:
		if bool(parent_node.get_meta("legacy_architecture_disabled", false)):
			return true
		parent_node = parent_node.get_parent()
	return false

func _disable_legacy_prop() -> void:
	visible = false
	collision_layer = 0
	collision_mask = 0
	if _shape != null:
		_shape.disabled = true

func _rebuild_collision() -> void:
	if not is_inside_tree():
		return
	if not solid:
		if _shape != null:
			_shape.disabled = true
		collision_layer = 0
		collision_mask = 0
		return
	if _shape == null:
		_shape = CollisionShape2D.new()
		_shape.name = "LegacyPropCollision"
		add_child(_shape)
	_shape.disabled = false
	var rectangle: RectangleShape2D = RectangleShape2D.new()
	rectangle.size = size
	_shape.shape = rectangle
	collision_layer = 1
	collision_mask = 1

func _draw() -> void:
	if _disabled_by_legacy_architecture():
		return
	var rect: Rect2 = Rect2(-size * 0.5, size)
	var accent: Color = Color("72E0C2") if prop_type == "generator" else Color("F3B84B") if prop_type == "console" else Color("647577")
	draw_rect(rect.grow(4.0), Color(0.0, 0.0, 0.0, 0.35), true)
	draw_rect(rect, prop_color, true)
	draw_rect(rect, Color("11181B"), false, 2.0)
	match prop_type:
		"crate":
			draw_line(rect.position, rect.end, Color(accent, 0.7), 2.0)
			draw_line(Vector2(rect.end.x, rect.position.y), Vector2(rect.position.x, rect.end.y), Color(accent, 0.7), 2.0)
		"shelf":
			for row in 3:
				var row_y: float = rect.position.y + 8.0 + row * (size.y - 16.0) / 2.0
				draw_line(Vector2(rect.position.x + 4.0, row_y), Vector2(rect.end.x - 4.0, row_y), accent, 2.0)
		"generator":
			draw_circle(Vector2.ZERO, minf(size.x, size.y) * 0.24, Color(accent, 0.8))
			draw_arc(Vector2.ZERO, minf(size.x, size.y) * 0.36, 0.0, TAU, 24, Color(accent, 0.6), 2.0)
		"console":
			draw_rect(Rect2(rect.position + Vector2(8.0, 8.0), Vector2(size.x - 16.0, size.y * 0.35)), Color(accent, 0.7), true)
		"pillar":
			draw_circle(Vector2.ZERO, minf(size.x, size.y) * 0.35, Color(accent, 0.35))
			draw_circle(Vector2.ZERO, minf(size.x, size.y) * 0.25, accent)
		"debris":
			draw_line(rect.position + Vector2(8.0, 8.0), rect.end - Vector2(8.0, 8.0), Color(accent, 0.65), 3.0)
