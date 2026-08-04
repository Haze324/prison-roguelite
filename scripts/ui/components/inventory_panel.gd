class_name InventoryPanelUI
extends Control

## 可复用装备/背包面板。
## 物品只显示图标；名称和数量仅在悬浮时提示；拖动过程中不绘制文字或拖影。

signal item_dropped(source_id: String, target_id: String)
signal slot_hovered(slot_id: String, record: Dictionary)

const INK: Color = Color("E7F1ED")
const MUTED: Color = Color("829795")
const MINT: Color = Color("61E4C0")
const AMBER: Color = Color("E7B455")
const RED: Color = Color("E56568")
const BLUE: Color = Color("74B9E8")
const PURPLE: Color = Color("B980E8")
const PANEL: Color = Color("0B151A")

@export var backpack_columns: int = 4
@export var backpack_rows: int = 3

var equipment_records: Dictionary = {}
var backpack_records: Array[Dictionary] = []
var _hover_slot_id: String = ""
var _hover_time: float = 0.0
var _drag_source_id: String = ""
var _tooltip_visible: bool = false

func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_STOP
	_set_empty_backpack()
	queue_redraw()

func set_inventory(equipment: Dictionary, backpack: Array[Dictionary]) -> void:
	equipment_records = equipment.duplicate(true)
	backpack_records = []
	for index in backpack.size():
		backpack_records.append(backpack[index].duplicate())
	while backpack_records.size() < backpack_columns * backpack_rows:
		backpack_records.append({})
	queue_redraw()

func set_equipment_record(slot_id: String, record: Dictionary) -> void:
	equipment_records[slot_id] = record.duplicate()
	queue_redraw()

func set_backpack_record(index: int, record: Dictionary) -> void:
	if index < 0 or index >= backpack_columns * backpack_rows:
		return
	while backpack_records.size() <= index:
		backpack_records.append({})
	backpack_records[index] = record.duplicate()
	queue_redraw()

func _process(delta: float) -> void:
	var next_hover: String = _slot_at(get_local_mouse_position())
	var should_redraw: bool = false
	if next_hover != _hover_slot_id:
		_hover_slot_id = next_hover
		_hover_time = 0.0
		_tooltip_visible = false
		should_redraw = true
		if next_hover != "":
			slot_hovered.emit(next_hover, _record_for(next_hover))
	else:
		_hover_time += delta
		var next_tooltip_visible: bool = next_hover != "" and _hover_time > 0.2 and not _is_empty(_record_for(next_hover))
		if next_tooltip_visible != _tooltip_visible:
			_tooltip_visible = next_tooltip_visible
			should_redraw = true
	if should_redraw:
		queue_redraw()

func _gui_input(event: InputEvent) -> void:
	if not event is InputEventMouseButton:
		return
	var mouse_event: InputEventMouseButton = event as InputEventMouseButton
	var slot_id: String = _slot_at(mouse_event.position)
	if mouse_event.button_index != MOUSE_BUTTON_LEFT or slot_id == "":
		return
	if mouse_event.pressed:
		if not _is_empty(_record_for(slot_id)):
			_drag_source_id = slot_id
			get_viewport().set_input_as_handled()
	else:
		if _drag_source_id != "" and slot_id != _drag_source_id:
			item_dropped.emit(_drag_source_id, slot_id)
		_drag_source_id = ""
		get_viewport().set_input_as_handled()

func _draw() -> void:
	var panel: Rect2 = Rect2(Vector2(0.0, 0.0), size)
	draw_rect(panel.grow(5.0), Color(0.0, 0.0, 0.0, 0.48), true)
	draw_rect(panel, Color(PANEL, 0.96), true)
	_draw_frame(panel, MINT)
	draw_string(ThemeDB.fallback_font, Vector2(24.0, 34.0), "现场背包", HORIZONTAL_ALIGNMENT_LEFT, -1.0, 24, INK)
	draw_string(ThemeDB.fallback_font, Vector2(26.0, 56.0), "拖动图标装备或卸下 · Tab 返回任务", HORIZONTAL_ALIGNMENT_LEFT, -1.0, 11, MUTED)

	var equipment_panel: Rect2 = _equipment_panel()
	var bag_panel: Rect2 = _backpack_panel()
	_draw_section(equipment_panel, "装备槽位", MINT)
	_draw_section(bag_panel, "背包槽位  //  4 × 3", AMBER)
	for slot_id in ["armor_head", "armor_hands", "armor_body", "weapon_1", "weapon_2", "healing", "consumable", "throwable_1", "throwable_2"]:
		var rect: Rect2 = _slot_rect(String(slot_id))
		_draw_slot(rect, String(slot_id), _record_for(String(slot_id)), _accent_for(String(slot_id)))
	for index in backpack_columns * backpack_rows:
		var bag_id: String = "backpack_%d" % index
		_draw_slot(_slot_rect(bag_id), bag_id, _record_for(bag_id), PURPLE)

	if _hover_slot_id != "" and _hover_time > 0.2:
		var hover_record: Dictionary = _record_for(_hover_slot_id)
		if not _is_empty(hover_record):
			_draw_tooltip(hover_record, get_local_mouse_position())

func _equipment_panel() -> Rect2:
	return Rect2(20.0, 80.0, size.x * 0.48, size.y - 126.0)

func _backpack_panel() -> Rect2:
	var left: float = size.x * 0.52
	return Rect2(left, 80.0, size.x - left - 20.0, size.y - 126.0)

func _slot_rect(slot_id: String) -> Rect2:
	var equipment: Rect2 = _equipment_panel()
	var bag: Rect2 = _backpack_panel()
	if slot_id.begins_with("backpack_"):
		var index: int = int(slot_id.trim_prefix("backpack_"))
		var gap: float = 10.0
		var cell_width: float = (bag.size.x - 28.0 - gap * float(backpack_columns - 1)) / float(backpack_columns)
		var cell_height: float = (bag.size.y - 62.0 - gap * float(backpack_rows - 1)) / float(backpack_rows)
		return Rect2(bag.position + Vector2(14.0 + float(index % backpack_columns) * (cell_width + gap), 48.0 + float(index / backpack_columns) * (cell_height + gap)), Vector2(cell_width, cell_height))
	var slot_size: Vector2 = Vector2((equipment.size.x - 48.0) / 3.0, 92.0)
	var armor_order: Array[String] = ["armor_head", "armor_hands", "armor_body"]
	var index: int = armor_order.find(slot_id)
	if index >= 0:
		return Rect2(equipment.position + Vector2(14.0 + float(index) * (slot_size.x + 10.0), 48.0), slot_size)
	var row: int = 1
	var weapon_index: int = ["weapon_1", "weapon_2"].find(slot_id)
	if weapon_index >= 0:
		return Rect2(equipment.position + Vector2(14.0 + float(weapon_index) * (equipment.size.x * 0.5 - 22.0), 170.0), Vector2(equipment.size.x * 0.5 - 24.0, 112.0))
	var lower: Array[String] = ["healing", "consumable", "throwable_1", "throwable_2"]
	var lower_index: int = lower.find(slot_id)
	if lower_index >= 0:
		return Rect2(equipment.position + Vector2(14.0 + float(lower_index) * ((equipment.size.x - 38.0) / 4.0), 316.0), Vector2((equipment.size.x - 48.0) / 4.0, 102.0))
	return Rect2(Vector2.ZERO, Vector2.ZERO)

func _slot_at(position: Vector2) -> String:
	for slot_id in ["armor_head", "armor_hands", "armor_body", "weapon_1", "weapon_2", "healing", "consumable", "throwable_1", "throwable_2"]:
		if _slot_rect(String(slot_id)).has_point(position):
			return String(slot_id)
	for index in backpack_columns * backpack_rows:
		var bag_id: String = "backpack_%d" % index
		if _slot_rect(bag_id).has_point(position):
			return bag_id
	return ""

func _record_for(slot_id: String) -> Dictionary:
	if slot_id.begins_with("backpack_"):
		var index: int = int(slot_id.trim_prefix("backpack_"))
		return backpack_records[index].duplicate() if index >= 0 and index < backpack_records.size() else {}
	return equipment_records.get(slot_id, {}).duplicate()

func _draw_section(rect: Rect2, title: String, accent: Color) -> void:
	draw_rect(rect, Color(accent, 0.045), true)
	draw_rect(rect, Color(accent, 0.6), false, 1.0)
	draw_string(ThemeDB.fallback_font, rect.position + Vector2(16.0, 28.0), title, HORIZONTAL_ALIGNMENT_LEFT, -1.0, 15, accent)
	draw_line(rect.position + Vector2(16.0, 38.0), rect.position + Vector2(rect.size.x - 16.0, 38.0), Color(accent, 0.35), 1.0)

func _draw_slot(rect: Rect2, slot_id: String, record: Dictionary, accent: Color) -> void:
	if rect.size.x <= 0.0:
		return
	var active: bool = slot_id == _hover_slot_id or slot_id == _drag_source_id
	draw_rect(rect, Color(accent, 0.12 if active else 0.06), true)
	draw_rect(rect, Color(accent, 0.92 if active else 0.48), false, 1.5 if active else 1.0)
	draw_line(rect.position + Vector2(6.0, 7.0), rect.position + Vector2(28.0, 7.0), accent, 2.0)
	draw_line(rect.position + Vector2(7.0, 6.0), rect.position + Vector2(7.0, 24.0), accent, 2.0)
	draw_string(ThemeDB.fallback_font, rect.position + Vector2(11.0, 19.0), _slot_label(slot_id), HORIZONTAL_ALIGNMENT_LEFT, -1.0, 11, INK)
	_draw_record(rect.get_center() + Vector2(0.0, 8.0), record, accent, minf(rect.size.x, rect.size.y) * 0.24)

func _draw_record(center: Vector2, record: Dictionary, accent: Color, icon_size: float) -> void:
	if _is_empty(record):
		var empty_rect: Rect2 = Rect2(center - Vector2(icon_size, icon_size), Vector2(icon_size * 2.0, icon_size * 2.0))
		draw_rect(empty_rect, Color(accent, 0.035), true)
		draw_rect(empty_rect, Color(accent, 0.34), false, 1.0)
		draw_line(empty_rect.position + Vector2(4.0, 4.0), empty_rect.end - Vector2(4.0, 4.0), Color(accent, 0.28), 1.0)
		draw_line(Vector2(empty_rect.end.x - 4.0, empty_rect.position.y + 4.0), Vector2(empty_rect.position.x + 4.0, empty_rect.end.y - 4.0), Color(accent, 0.28), 1.0)
		return
	var icon: Texture2D = record.get("icon") as Texture2D
	if icon != null:
		_draw_texture_contained(icon, Rect2(center - Vector2(icon_size, icon_size), Vector2(icon_size * 2.0, icon_size * 2.0)))
	else:
		var kind: String = String(record.get("kind", ""))
		var item_key: String = String(record.get("key", ""))
		if kind == "healing" or item_key == "medkit":
			draw_circle(center, icon_size * 0.72, Color(RED, 0.18))
			draw_circle(center, icon_size * 0.42, RED)
			draw_rect(Rect2(center - Vector2(3.0, icon_size * 0.48), Vector2(6.0, icon_size * 0.96)), INK, true)
			draw_rect(Rect2(center - Vector2(icon_size * 0.48, 3.0), Vector2(icon_size * 0.96, 6.0)), INK, true)
		else:
			draw_circle(center, icon_size * 0.7, Color(accent, 0.2))
			draw_circle(center, icon_size * 0.42, accent)
	_draw_count(center, int(record.get("count", 0)), accent)

func _draw_count(center: Vector2, count: int, accent: Color) -> void:
	if count > 0:
		draw_string(ThemeDB.fallback_font, center + Vector2(18.0, 18.0), str(count), HORIZONTAL_ALIGNMENT_LEFT, -1.0, 11, accent)

func _draw_texture_contained(texture: Texture2D, box: Rect2) -> void:
	var texture_size: Vector2 = texture.get_size()
	if texture_size.x <= 0.0 or texture_size.y <= 0.0:
		return
	var scale: float = minf(box.size.x / texture_size.x, box.size.y / texture_size.y)
	var drawn_size: Vector2 = texture_size * scale
	draw_texture_rect(texture, Rect2(box.position + (box.size - drawn_size) * 0.5, drawn_size), false)

func _draw_tooltip(record: Dictionary, mouse_position: Vector2) -> void:
	var title: String = String(record.get("name", "物品"))
	var count: int = int(record.get("count", 0))
	var text: String = "%s  ×%d" % [title, count] if count > 0 else title
	var box: Rect2 = Rect2(mouse_position + Vector2(14.0, 14.0), Vector2(190.0, 32.0))
	if box.end.x > size.x:
		box.position.x = size.x - box.size.x - 8.0
	if box.end.y > size.y:
		box.position.y = mouse_position.y - box.size.y - 8.0
	draw_rect(box.grow(3.0), Color(0.0, 0.0, 0.0, 0.55), true)
	draw_rect(box, Color(PANEL, 0.98), true)
	draw_rect(box, MINT, false, 1.0)
	draw_string(ThemeDB.fallback_font, box.position + Vector2(10.0, 21.0), text, HORIZONTAL_ALIGNMENT_LEFT, box.size.x - 20.0, 12, INK)

func _draw_frame(rect: Rect2, accent: Color) -> void:
	draw_rect(rect, Color(accent, 0.8), false, 1.0)
	draw_line(rect.position + Vector2(0.0, 10.0), rect.position + Vector2(32.0, 10.0), accent, 2.0)
	draw_line(rect.position + Vector2(10.0, 0.0), rect.position + Vector2(10.0, 32.0), accent, 2.0)
	draw_line(Vector2(rect.end.x - 32.0, rect.position.y + 10.0), Vector2(rect.end.x, rect.position.y + 10.0), accent, 2.0)
	draw_line(Vector2(rect.end.x - 10.0, rect.end.y - 32.0), Vector2(rect.end.x - 10.0, rect.end.y), accent, 2.0)

func _slot_label(slot_id: String) -> String:
	match slot_id:
		"armor_head": return "头部"
		"armor_hands": return "手部"
		"armor_body": return "身体"
		"weapon_1": return "武器 1"
		"weapon_2": return "武器 2"
		"healing": return "Q"
		"consumable": return "F"
		"throwable_1": return "3"
		"throwable_2": return "4"
		_:
			return slot_id.trim_prefix("backpack_")

func _accent_for(slot_id: String) -> Color:
	if slot_id.begins_with("armor_") or slot_id == "weapon_2":
		return BLUE
	if slot_id == "weapon_1":
		return AMBER
	if slot_id == "healing":
		return RED
	if slot_id == "consumable":
		return PURPLE
	return AMBER

func _set_empty_backpack() -> void:
	backpack_records.clear()
	for _index in backpack_columns * backpack_rows:
		backpack_records.append({})

func _is_empty(record: Dictionary) -> bool:
	return record.is_empty() or int(record.get("count", 0)) <= 0
