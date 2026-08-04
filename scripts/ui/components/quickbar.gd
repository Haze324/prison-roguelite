class_name QuickbarUI
extends Control

## 可复用六槽快捷栏。
## 逻辑槽位顺序仍为 1、2、医疗、消耗品、投掷物 1、投掷物 2，
## 视觉顺序固定为 1、2、Q、F、3、4，和玩家操作协议保持一致。

signal slot_pressed(logical_slot: int)
signal slot_hovered(logical_slot: int, record: Dictionary)

const INK: Color = Color("E7F1ED")
const MUTED: Color = Color("7F9695")
const MINT: Color = Color("61E4C0")
const AMBER: Color = Color("E7B455")
const RED: Color = Color("E56568")
const BLUE: Color = Color("74B9E8")
const PURPLE: Color = Color("B980E8")

@export var slot_size: float = 62.0
@export var slot_gap: float = 8.0
@export var show_tooltip: bool = true

var _logical_records: Array[Dictionary] = [{}, {}, {}, {}, {}, {}]
var _selected_logical_slot: int = 0
var _reload_ratio: float = 0.0
var _hover_visual_slot: int = -1
var _hover_time: float = 0.0
var _tooltip_visible: bool = false

func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_STOP
	custom_minimum_size = Vector2(slot_size * 6.0 + slot_gap * 5.0, slot_size)
	_process_layout()

func _notification(what: int) -> void:
	if what == NOTIFICATION_RESIZED:
		_process_layout()

func set_logical_slots(records: Array[Dictionary]) -> void:
	_logical_records = [{}, {}, {}, {}, {}, {}]
	for index in mini(records.size(), 6):
		_logical_records[index] = records[index].duplicate()
	queue_redraw()

func set_slot(logical_slot: int, record: Dictionary) -> void:
	if logical_slot < 0 or logical_slot >= 6:
		return
	_logical_records[logical_slot] = record.duplicate()
	queue_redraw()

func set_selected_logical_slot(logical_slot: int) -> void:
	_selected_logical_slot = clampi(logical_slot, 0, 5)
	queue_redraw()

func set_reload_ratio(ratio: float) -> void:
	_reload_ratio = clampf(ratio, 0.0, 1.0)
	queue_redraw()

func _process(delta: float) -> void:
	var mouse_position: Vector2 = get_local_mouse_position()
	var next_hover: int = _visual_slot_at(mouse_position)
	var should_redraw: bool = _reload_ratio > 0.0
	if next_hover != _hover_visual_slot:
		_hover_visual_slot = next_hover
		_hover_time = 0.0
		_tooltip_visible = false
		should_redraw = true
		if next_hover >= 0:
			var logical_slot: int = _visual_to_logical(next_hover)
			slot_hovered.emit(logical_slot, _logical_records[logical_slot])
	else:
		_hover_time += delta
		var next_tooltip_visible: bool = show_tooltip and next_hover >= 0 and _hover_time > 0.22
		if next_tooltip_visible != _tooltip_visible:
			_tooltip_visible = next_tooltip_visible
			should_redraw = true
	if should_redraw:
		queue_redraw()

func _gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton:
		var mouse_event: InputEventMouseButton = event as InputEventMouseButton
		if mouse_event.pressed and mouse_event.button_index == MOUSE_BUTTON_LEFT:
			var visual_slot: int = _visual_slot_at(mouse_event.position)
			if visual_slot >= 0:
				slot_pressed.emit(_visual_to_logical(visual_slot))
				get_viewport().set_input_as_handled()

func _process_layout() -> void:
	if size.x <= 0.0 or size.y <= 0.0:
		size = custom_minimum_size

func _visual_to_logical(visual_slot: int) -> int:
	var order: Array[int] = [0, 1, 4, 5, 2, 3]
	return order[visual_slot] if visual_slot >= 0 and visual_slot < order.size() else -1

func _visual_slot_at(position: Vector2) -> int:
	var step: float = slot_size + slot_gap
	var slot: int = floori(position.x / step)
	if slot < 0 or slot >= 6:
		return -1
	var local_x: float = position.x - float(slot) * step
	if local_x > slot_size or position.y < 0.0 or position.y > slot_size:
		return -1
	return slot

func _draw() -> void:
	var visual_labels: Array[String] = ["1", "2", "Q", "F", "3", "4"]
	for visual_slot in 6:
		var logical_slot: int = _visual_to_logical(visual_slot)
		var position: Vector2 = Vector2(float(visual_slot) * (slot_size + slot_gap), 0.0)
		var accent: Color = _accent_for(logical_slot)
		var selected: bool = logical_slot == _selected_logical_slot
		_draw_slot(Rect2(position, Vector2(slot_size, slot_size)), accent, selected, visual_labels[visual_slot])
		_draw_record(position + Vector2(slot_size * 0.5, slot_size * 0.53), _logical_records[logical_slot], accent)
		if selected and logical_slot < 2 and _reload_ratio > 0.0:
			_draw_reload_overlay(position, _reload_ratio)
	if show_tooltip and _hover_visual_slot >= 0 and _hover_time > 0.22:
		_draw_tooltip(_hover_visual_slot)

func _draw_slot(rect: Rect2, accent: Color, selected: bool, label: String) -> void:
	var fill: Color = Color(accent, 0.18 if selected else 0.08)
	draw_rect(rect.grow(3.0), Color(0.0, 0.0, 0.0, 0.5), true)
	draw_rect(rect, fill, true)
	draw_rect(rect, accent if selected else Color("52666D"), false, 1.5 if selected else 1.0)
	draw_line(rect.position + Vector2(4.0, 5.0), rect.position + Vector2(22.0, 5.0), accent, 2.0)
	draw_line(rect.position + Vector2(5.0, 4.0), rect.position + Vector2(5.0, 20.0), accent, 2.0)
	draw_string(ThemeDB.fallback_font, rect.position + Vector2(8.0, 17.0), label, HORIZONTAL_ALIGNMENT_LEFT, -1.0, 11, INK)

func _draw_record(center: Vector2, record: Dictionary, accent: Color) -> void:
	if _is_empty(record):
		var empty_rect: Rect2 = Rect2(center - Vector2(13.0, 13.0), Vector2(26.0, 26.0))
		draw_rect(empty_rect, Color(accent, 0.035), true)
		draw_rect(empty_rect, Color(accent, 0.34), false, 1.0)
		draw_line(empty_rect.position + Vector2(5.0, 5.0), empty_rect.end - Vector2(5.0, 5.0), Color(accent, 0.3), 1.0)
		draw_line(Vector2(empty_rect.end.x - 5.0, empty_rect.position.y + 5.0), Vector2(empty_rect.position.x + 5.0, empty_rect.end.y - 5.0), Color(accent, 0.3), 1.0)
		return
	var icon: Texture2D = record.get("icon") as Texture2D
	if icon != null:
		_draw_texture_contained(icon, Rect2(center - Vector2(21.0, 18.0), Vector2(42.0, 36.0)))
		_draw_count(center, int(record.get("count", 0)), accent)
		return
	var item_key: String = String(record.get("key", ""))
	var kind: String = String(record.get("kind", ""))
	var item_color: Color = accent
	if kind == "healing" or item_key == "medkit":
		draw_circle(center, 13.0, Color(RED, 0.18))
		draw_circle(center, 8.0, RED)
		draw_rect(Rect2(center - Vector2(2.0, 6.0), Vector2(4.0, 12.0)), INK, true)
		draw_rect(Rect2(center - Vector2(6.0, 2.0), Vector2(12.0, 4.0)), INK, true)
	elif item_key == "ammo_box":
		draw_rect(Rect2(center - Vector2(15.0, 10.0), Vector2(30.0, 20.0)), Color(BLUE, 0.2), true)
		draw_rect(Rect2(center - Vector2(15.0, 10.0), Vector2(30.0, 20.0)), BLUE, false, 2.0)
		draw_line(center - Vector2(9.0, 0.0), center + Vector2(9.0, 0.0), BLUE, 2.0)
	elif item_key == "adrenaline":
		var lightning: PackedVector2Array = PackedVector2Array([center + Vector2(-4.0, -14.0), center + Vector2(5.0, -2.0), center + Vector2(1.0, -2.0), center + Vector2(5.0, 14.0), center + Vector2(-6.0, 2.0), center + Vector2(-1.0, 2.0)])
		draw_colored_polygon(lightning, AMBER)
	else:
		draw_circle(center, 11.0, Color(item_color, 0.18))
		draw_circle(center, 7.0, item_color)
		draw_arc(center, 14.0, 0.0, TAU, 20, Color(item_color, 0.8), 2.0)
	_draw_count(center, int(record.get("count", 0)), accent)

func _draw_count(center: Vector2, count: int, accent: Color) -> void:
	if count <= 0:
		return
	draw_string(ThemeDB.fallback_font, center + Vector2(18.0, 18.0), str(count), HORIZONTAL_ALIGNMENT_LEFT, -1.0, 11, accent)

func _draw_texture_contained(texture: Texture2D, box: Rect2) -> void:
	var texture_size: Vector2 = texture.get_size()
	if texture_size.x <= 0.0 or texture_size.y <= 0.0:
		return
	var fit_scale: float = minf(box.size.x / texture_size.x, box.size.y / texture_size.y)
	var drawn_size: Vector2 = texture_size * fit_scale
	var destination: Rect2 = Rect2(box.position + (box.size - drawn_size) * 0.5, drawn_size)
	draw_texture_rect(texture, destination, false)

func _draw_reload_overlay(position: Vector2, ratio: float) -> void:
	var center: Vector2 = position + Vector2(slot_size * 0.5, slot_size * 0.53)
	var points: PackedVector2Array = PackedVector2Array([center])
	for index in 25:
		var angle: float = -PI * 0.5 + TAU * ratio * float(index) / 24.0
		points.append(center + Vector2.from_angle(angle) * (slot_size * 0.49))
	draw_colored_polygon(points, Color(0.18, 0.21, 0.22, 0.72))
	draw_arc(center, slot_size * 0.44, -PI * 0.5, -PI * 0.5 + TAU * ratio, 24, Color(0.82, 0.86, 0.84, 0.92), 2.0)

func _draw_tooltip(visual_slot: int) -> void:
	var logical_slot: int = _visual_to_logical(visual_slot)
	var record: Dictionary = _logical_records[logical_slot]
	var title: String = String(record.get("name", "空槽")) if not _is_empty(record) else "空槽"
	var count: int = int(record.get("count", 0))
	var text: String = title if count <= 0 else "%s  ×%d" % [title, count]
	var box: Rect2 = Rect2(Vector2(float(visual_slot) * (slot_size + slot_gap), -42.0), Vector2(142.0, 30.0))
	if box.end.x > size.x:
		box.position.x = size.x - box.size.x
	draw_rect(box.grow(3.0), Color(0.0, 0.0, 0.0, 0.55), true)
	draw_rect(box, Color("0B151A", 0.97), true)
	draw_rect(box, _accent_for(logical_slot), false, 1.0)
	draw_string(ThemeDB.fallback_font, box.position + Vector2(9.0, 20.0), text, HORIZONTAL_ALIGNMENT_LEFT, box.size.x - 18.0, 11, INK)

func _is_empty(record: Dictionary) -> bool:
	return record.is_empty() or int(record.get("count", 0)) <= 0

func _accent_for(logical_slot: int) -> Color:
	match logical_slot:
		0:
			return AMBER
		1:
			return BLUE
		2:
			return RED
		3:
			return PURPLE
		4:
			return AMBER
		_:
			return PURPLE
