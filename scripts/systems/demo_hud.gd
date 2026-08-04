class_name DemoHUD
extends Control

## 最终版中文 HUD：只使用 Godot 绘图 API，不依赖外部 UI 素材。
const BG: Color = Color("0B1118")
const PANEL: Color = Color("111C25")
const PANEL_LIGHT: Color = Color("182934")
const INK: Color = Color("E8F0E9")
const MUTED: Color = Color("94A9A5")
const MINT: Color = Color("72E0C2")
const AMBER: Color = Color("F3B84B")
const RED: Color = Color("F0646D")
const BLUE: Color = Color("77B9E8")
const PURPLE: Color = Color("B58AE8")

var health: float = 100.0
var max_health: float = 100.0
var medkits: int = 0
var consumable_name: String = "弹药箱"
var throwable_slot_names: Array[String] = ["信号弹", "烟雾弹"]
var weapon_name: String = "无"
var ammo: int = 0
var ammo_capacity: int = 0
var ammo_reserve: int = 0
var player_state: String = "待机"
var temporary_noise: float = 0.0
var residual_noise: float = 0.0
var kills: int = 0
var boss_text: String = "沉睡"
var boss_health: float = 0.0
var boss_max_health: float = 1.0
var event_text: String = "等待行动"
var power_fixed: int = 0
var power_total: int = 3
var armor_durability: int = 0
var armor_maximum: int = 0
var throwable_summary: String = "信号弹 1  烟雾弹 1  手雷 1  地雷 1"
var quick_slot_counts: Array[int] = [0, 0, 0, 0]
var selected_quick_slot: int = 0
var weapon_one_icon: Texture2D
var weapon_two_icon: Texture2D
var current_weapon_slot: int = 0
var reload_ratio: float = 0.0
var coins: int = 0
var skill_points: int = 0
var map_label: String = "FACILITY 07"
var inventory_open: bool = false
var inventory_drag_source: String = ""
var damage_flash_remaining: float = 0.0
var parry_flash_remaining: float = 0.0
var boss_alert_remaining: float = 0.0
var _player: Player
var _inventory_ui_signature: String = ""
var _last_cursor_position: Vector2 = Vector2(-99999.0, -99999.0)
## Avoid compile-time dependency on the editor's global class cache for map HUD data.
@onready var _map_manager: Node = get_node_or_null("../../MapManager")
@onready var health_gauge: HealthGauge = get_node_or_null("HealthGauge") as HealthGauge
@onready var noise_meter: NoiseMeter = get_node_or_null("NoiseMeter") as NoiseMeter
@onready var quickbar_ui: Control = get_node_or_null("../QuickbarUI") as Control
@onready var inventory_panel_ui: Control = get_node_or_null("../InventoryPanelUI") as Control
var screen_phase: String = "菜单"

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	_player = get_node_or_null("../../Player") as Player
	EventBus.damage_feedback.connect(_on_damage_feedback)
	EventBus.player_parried.connect(_on_player_parried)
	if quickbar_ui != null:
		quickbar_ui.connect("slot_pressed", Callable(self, "_on_quickbar_slot_pressed"))
	if inventory_panel_ui != null:
		inventory_panel_ui.connect("item_dropped", Callable(self, "_on_inventory_item_dropped"))
	_sync_ui_components()
	queue_redraw()

func _input(event: InputEvent) -> void:
	if event is InputEventKey and event.is_pressed() and not event.is_echo() and (event as InputEventKey).physical_keycode == KEY_M:
		if screen_phase == "战斗":
			show_map()
			get_viewport().set_input_as_handled()
		elif screen_phase == "地图":
			show_run()
			get_viewport().set_input_as_handled()
		return
	var inventory_pressed: bool = event.is_action_pressed("inventory")
	if event is InputEventKey and event.is_pressed() and not event.is_echo():
		inventory_pressed = inventory_pressed or (event as InputEventKey).physical_keycode == KEY_TAB
	if inventory_pressed and (screen_phase == "战斗" or inventory_open):
		inventory_open = not inventory_open
		get_tree().paused = inventory_open
		queue_redraw()
		get_viewport().set_input_as_handled()
		return
	if event is InputEventMouseButton:
		var mouse_event: InputEventMouseButton = event as InputEventMouseButton
		if mouse_event.button_index == MOUSE_BUTTON_LEFT:
			if mouse_event.pressed:
				if screen_phase == "菜单" and _screen_action_rect(get_viewport_rect().size).has_point(mouse_event.position):
					EventBus.run_start_requested.emit()
					get_viewport().set_input_as_handled()
				elif (screen_phase == "失败" or screen_phase == "结算") and _screen_action_rect(get_viewport_rect().size).has_point(mouse_event.position):
					EventBus.run_restart_requested.emit()
					get_viewport().set_input_as_handled()
				elif inventory_open:
					if inventory_panel_ui == null:
						inventory_drag_source = _inventory_hit_test(mouse_event.position)
				elif screen_phase == "战斗":
					if quickbar_ui == null:
						var active_slot: int = _combat_slot_hit_test(mouse_event.position)
						if active_slot >= 0 and _player != null:
							_player.select_active_slot(_quickbar_logical_slot(active_slot), true)
							get_viewport().set_input_as_handled()
			else:
				if inventory_open and inventory_panel_ui == null:
					var target_slot: String = _inventory_hit_test(mouse_event.position)
					if inventory_drag_source != "" and _player != null and is_instance_valid(_player) and target_slot != "":
						_player.move_inventory_item(inventory_drag_source, target_slot)
						_refresh_inventory_view_from_player()
					inventory_drag_source = ""
					queue_redraw()
					get_viewport().set_input_as_handled()
	elif event.is_action_pressed("ui_accept") and screen_phase == "菜单":
		EventBus.run_start_requested.emit()
		get_viewport().set_input_as_handled()
	elif event.is_action_pressed("ui_accept") and (screen_phase == "失败" or screen_phase == "结算"):
		EventBus.run_restart_requested.emit()
		get_viewport().set_input_as_handled()

func show_main_menu() -> void:
	screen_phase = "菜单"
	inventory_open = false
	get_tree().paused = true
	queue_redraw()

func show_run() -> void:
	screen_phase = "战斗"
	inventory_open = false
	get_tree().paused = false
	if quickbar_ui != null:
		quickbar_ui.visible = true
		quickbar_ui.z_index = 20
	if inventory_panel_ui != null:
		inventory_panel_ui.visible = false
	call_deferred("_sync_ui_components")
	queue_redraw()

func show_map() -> void:
	screen_phase = "地图"
	inventory_open = false
	get_tree().paused = true
	queue_redraw()

func show_death() -> void:
	screen_phase = "失败"
	inventory_open = false
	get_tree().paused = true
	queue_redraw()

func show_result() -> void:
	screen_phase = "结算"
	inventory_open = false
	get_tree().paused = true
	queue_redraw()

func set_map_label(label: String) -> void:
	map_label = label.to_upper() if not label.is_empty() else "FACILITY 07"
	queue_redraw()

func set_data(
	current_health: float,
	maximum_health: float,
	current_medkits: int,
	current_weapon: String,
	current_ammo: int,
	capacity: int,
	reserve: int,
	state: String,
	temp_noise: float,
	residual: float,
	defeated: int,
	boss_status: String,
	current_boss_health: float,
	maximum_boss_health: float,
	latest_event: String,
	current_power: int,
	total_power: int,
	current_armor: int,
	maximum_armor: int,
	throwables: String,
	current_quick_slot_counts: Array[int],
	current_selected_quick_slot: int,
	meta_coins: int,
	meta_skill_points: int,
	current_weapon_texture: Texture2D = null,
	secondary_weapon_texture: Texture2D = null,
	weapon_slot: int = 0,
	current_reload_ratio: float = 0.0,
	current_consumable_name: String = "弹药箱",
	current_throwable_names: Array[String] = []
) -> void:
	health = current_health
	max_health = maximum_health
	medkits = current_medkits
	weapon_name = _translate_weapon_name(current_weapon)
	ammo = current_ammo
	ammo_capacity = capacity
	ammo_reserve = reserve
	player_state = _translate_state(state)
	temporary_noise = temp_noise
	residual_noise = residual
	kills = defeated
	boss_text = _translate_boss(boss_status)
	boss_health = current_boss_health
	boss_max_health = maximum_boss_health
	event_text = _translate_event(latest_event)
	power_fixed = current_power
	power_total = total_power
	armor_durability = current_armor
	armor_maximum = maximum_armor
	throwable_summary = _translate_throwables(throwables)
	quick_slot_counts = current_quick_slot_counts.duplicate()
	selected_quick_slot = current_selected_quick_slot
	consumable_name = current_consumable_name
	if current_throwable_names.size() >= 2:
		throwable_slot_names = current_throwable_names.duplicate()
	weapon_one_icon = current_weapon_texture
	weapon_two_icon = secondary_weapon_texture
	current_weapon_slot = weapon_slot
	reload_ratio = current_reload_ratio
	coins = meta_coins
	skill_points = meta_skill_points
	queue_redraw()

func _process(delta: float) -> void:
	var previous_damage: float = damage_flash_remaining
	var previous_parry: float = parry_flash_remaining
	var previous_boss_alert: float = boss_alert_remaining
	damage_flash_remaining = maxf(damage_flash_remaining - delta, 0.0)
	parry_flash_remaining = maxf(parry_flash_remaining - delta, 0.0)
	boss_alert_remaining = maxf(boss_alert_remaining - delta, 0.0)
	if inventory_open:
		_refresh_inventory_view_from_player()
	_sync_ui_components()
	var cursor_position: Vector2 = get_viewport().get_mouse_position()
	var cursor_changed: bool = cursor_position.distance_squared_to(_last_cursor_position) > 0.25
	_last_cursor_position = cursor_position
	var effects_changed: bool = not is_equal_approx(previous_damage, damage_flash_remaining) or not is_equal_approx(previous_parry, parry_flash_remaining) or not is_equal_approx(previous_boss_alert, boss_alert_remaining)
	if cursor_changed or effects_changed or inventory_open:
		queue_redraw()

func _sync_ui_components() -> void:
	var viewport_size: Vector2 = get_viewport_rect().size
	var combat_visible: bool = screen_phase == "战斗" and not inventory_open
	if health_gauge != null:
		health_gauge.visible = combat_visible
		health_gauge.set_value(health, max_health)
	if noise_meter != null:
		noise_meter.visible = combat_visible
		noise_meter.set_value(temporary_noise + residual_noise)
	if quickbar_ui != null:
		quickbar_ui.set_anchors_and_offsets_preset(Control.PRESET_TOP_LEFT)
		quickbar_ui.size = Vector2(478.0, 62.0)
		quickbar_ui.position = Vector2(maxf((viewport_size.x - quickbar_ui.size.x) * 0.5, 12.0), maxf(viewport_size.y - quickbar_ui.size.y - 22.0, 12.0))
		quickbar_ui.visible = combat_visible
		if _player != null and is_instance_valid(_player):
			var quickbar_records: Array[Dictionary] = [
				_player.get_inventory_record("weapon_1"),
				_player.get_inventory_record("weapon_2"),
				_player.get_inventory_record("healing"),
				_player.get_inventory_record("consumable"),
				_player.get_inventory_record("throwable_1"),
				_player.get_inventory_record("throwable_2"),
			]
			quickbar_ui.call("set_logical_slots", quickbar_records)
			quickbar_ui.call("set_selected_logical_slot", _player.selected_active_slot)
			quickbar_ui.call("set_reload_ratio", _player.get_reload_ratio())
	if inventory_panel_ui != null:
		inventory_panel_ui.set_anchors_and_offsets_preset(Control.PRESET_TOP_LEFT)
		inventory_panel_ui.position = Vector2.ZERO
		inventory_panel_ui.size = viewport_size
		inventory_panel_ui.visible = inventory_open
		if inventory_open and _player != null and is_instance_valid(_player):
			var equipment_records: Dictionary = {}
			for slot_id in ["armor_head", "armor_hands", "armor_body", "weapon_1", "weapon_2", "healing", "consumable", "throwable_1", "throwable_2"]:
				equipment_records[slot_id] = _player.get_inventory_record(slot_id)
			var backpack_records: Array[Dictionary] = []
			for index in 12:
				backpack_records.append(_player.get_inventory_record("backpack_%d" % index))
			var inventory_signature: String = str(equipment_records) + str(backpack_records)
			if inventory_signature != _inventory_ui_signature:
				_inventory_ui_signature = inventory_signature
				inventory_panel_ui.call("set_inventory", equipment_records, backpack_records)

func _on_quickbar_slot_pressed(logical_slot: int) -> void:
	if _player != null and is_instance_valid(_player) and screen_phase == "战斗":
		_player.select_active_slot(logical_slot, true)

func _on_inventory_item_dropped(source_id: String, target_id: String) -> void:
	if _player == null or not is_instance_valid(_player):
		return
	if _player.move_inventory_item(source_id, target_id):
		_refresh_inventory_view_from_player()
		_sync_ui_components()

func _refresh_inventory_view_from_player() -> void:
	if _player == null or not is_instance_valid(_player):
		return
	medkits = _player.medkits
	quick_slot_counts = _player.get_active_slot_counts()
	consumable_name = _player.consumable_display_name(_player.consumable_slot_item)
	throwable_slot_names = [
		_player.throwable_display_name(_player.throwable_slot_items[0]),
		_player.throwable_display_name(_player.throwable_slot_items[1]),
	]
	weapon_one_icon = _player.get_weapon_display_icon(0)
	weapon_two_icon = _player.get_weapon_display_icon(1)
	current_weapon_slot = _player.current_weapon_index
	reload_ratio = _player.get_reload_ratio()

func _draw() -> void:
	var screen: Vector2 = get_viewport_rect().size
	var font: Font = ThemeDB.fallback_font
	var noise_total: float = temporary_noise + residual_noise
	# Keep the component layer authoritative even when the scene is resized while paused.
	if screen_phase == "战斗" and not inventory_open and quickbar_ui != null:
		quickbar_ui.visible = true
	if inventory_open:
		if inventory_panel_ui == null:
			_draw_inventory(font, screen)
	elif screen_phase == "战斗":
		_draw_combat_hud(font, screen, noise_total)
	elif screen_phase == "地图":
		_draw_map(font, screen)
	else:
		_draw_screen_overlay(font, screen)

func _draw_combat_hud(font: Font, screen: Vector2, noise_total: float) -> void:
	var status_rect: Rect2 = Rect2(18.0, 18.0, 342.0, 178.0)
	_draw_card(status_rect, MINT, 0.94)
	_draw_label(font, status_rect.position + Vector2(16.0, 25.0), "生还者", 17, INK)
	_draw_label(font, status_rect.position + Vector2(174.0, 24.0), map_label.to_upper(), 10, MINT)
	_draw_label(font, status_rect.position + Vector2(16.0, 48.0), "生命", 11, MUTED)
	_draw_label(font, status_rect.position + Vector2(270.0, 49.0), "%d" % roundi(health), 11, INK)
	_draw_label(font, status_rect.position + Vector2(16.0, 73.0), "护甲", 11, MUTED)
	_draw_bar(Rect2(status_rect.position + Vector2(64.0, 63.0), Vector2(194.0, 11.0)), armor_durability / maxf(armor_maximum, 1), BLUE)
	_draw_label(font, status_rect.position + Vector2(270.0, 74.0), "%d" % armor_durability, 11, INK)
	_draw_label(font, status_rect.position + Vector2(16.0, 101.0), "武器", 11, MUTED)
	_draw_label(font, status_rect.position + Vector2(64.0, 101.0), weapon_name, 12, AMBER)
	_draw_label(font, status_rect.position + Vector2(16.0, 126.0), "弹药", 11, MUTED)
	_draw_label(font, status_rect.position + Vector2(64.0, 126.0), "%d / %d  + %d" % [ammo, ammo_capacity, ammo_reserve], 12, MINT)
	_draw_label(font, status_rect.position + Vector2(16.0, 151.0), "目标", 11, MUTED)
	_draw_label(font, status_rect.position + Vector2(64.0, 151.0), "电源 %d / %d" % [power_fixed, power_total], 11, AMBER)
	_draw_label(font, status_rect.position + Vector2(190.0, 151.0), "Q 血瓶 ×%d" % medkits, 11, RED)

	var threat_rect: Rect2 = Rect2(screen.x - 278.0, 18.0, 260.0, 184.0)
	_draw_card(threat_rect, AMBER if noise_total > 50.0 else MINT, 0.94)
	_draw_label(font, threat_rect.position + Vector2(16.0, 25.0), "威胁监测", 17, INK)
	_draw_label(font, threat_rect.position + Vector2(16.0, 49.0), "噪声", 11, MUTED)
	var noise_color: Color = MINT if noise_total <= 50.0 else AMBER if noise_total <= 120.0 else RED
	_draw_label(font, threat_rect.position + Vector2(178.0, 82.0), "%.0f / 200" % noise_total, 12, noise_color)
	_draw_label(font, threat_rect.position + Vector2(178.0, 101.0), _noise_label(noise_total), 11, noise_color)
	_draw_label(font, threat_rect.position + Vector2(16.0, 139.0), "守卫者", 11, MUTED)
	_draw_label(font, threat_rect.position + Vector2(78.0, 139.0), boss_text, 12, RED if boss_text != "沉睡" else MINT)

	if boss_health > 0.0:
		var boss_rect: Rect2 = Rect2(screen.x * 0.5 - 250.0, 208.0, 500.0, 48.0)
		_draw_label(font, boss_rect.position, "守卫者  " + boss_text, 12, RED)
		_draw_bar(Rect2(boss_rect.position + Vector2(0.0, 15.0), Vector2(500.0, 14.0)), boss_health / maxf(boss_max_health, 1.0), RED)

	var event_rect: Rect2 = Rect2(18.0, screen.y - 78.0, screen.x - 36.0, 32.0)
	_draw_card(event_rect, Color("60747B"), 0.9)
	_draw_label(font, event_rect.position + Vector2(12.0, 21.0), "提示  /  " + event_text, 12, INK)
	if quickbar_ui == null:
		_draw_quickbar(font, screen)
	if boss_alert_remaining > 0.0:
		var edge_alpha: float = 0.16 + sin(Time.get_ticks_msec() * 0.012) * 0.07
		draw_rect(Rect2(0.0, 0.0, screen.x, 10.0), Color(RED, edge_alpha), true)
		draw_rect(Rect2(0.0, screen.y - 10.0, screen.x, 10.0), Color(RED, edge_alpha), true)
		draw_rect(Rect2(0.0, 0.0, 10.0, screen.y), Color(RED, edge_alpha), true)
		draw_rect(Rect2(screen.x - 10.0, 0.0, 10.0, screen.y), Color(RED, edge_alpha), true)
	_draw_aim_reticle()
	if damage_flash_remaining > 0.0:
		draw_rect(Rect2(Vector2.ZERO, screen), Color(RED, damage_flash_remaining / 0.22 * 0.24), true)
	if parry_flash_remaining > 0.0:
		draw_rect(Rect2(Vector2.ZERO, screen), Color(BLUE, parry_flash_remaining / 0.28 * 0.24), true)

func _draw_aim_reticle() -> void:
	var cursor: Vector2 = get_viewport().get_mouse_position()
	var aiming: bool = _player != null and _player.is_aiming
	var color: Color = BLUE if aiming else MINT
	var radius: float = 13.0 if aiming else 9.0
	draw_circle(cursor, 2.0, color)
	draw_line(cursor + Vector2(-radius - 7.0, 0.0), cursor + Vector2(-radius, 0.0), color, 2.0)
	draw_line(cursor + Vector2(radius, 0.0), cursor + Vector2(radius + 7.0, 0.0), color, 2.0)
	draw_line(cursor + Vector2(0.0, -radius - 7.0), cursor + Vector2(0.0, -radius), color, 2.0)
	draw_line(cursor + Vector2(0.0, radius), cursor + Vector2(0.0, radius + 7.0), color, 2.0)
	if aiming:
		draw_arc(cursor, radius, 0.0, TAU, 24, Color(color, 0.75), 1.5)

func _draw_quickbar(font: Font, screen: Vector2) -> void:
	var slot_size: float = 56.0
	var gap: float = 8.0
	var total_width: float = slot_size * 6.0 + gap * 5.0
	var start_x: float = (screen.x - total_width) * 0.5
	var y: float = screen.y - 156.0
	for index in 6:
		_draw_quick_slot(font, Vector2(start_x + index * (slot_size + gap), y), slot_size, index)

func _draw_quick_slot(font: Font, position: Vector2, slot_size: float, index: int) -> void:
	var logical_slot: int = _quickbar_logical_slot(index)
	var is_weapon_slot: bool = logical_slot < 2
	var tint: Color = [AMBER, BLUE, RED, PURPLE, Color("E6D36A"), Color("C47AE8")][logical_slot]
	var selected: bool = current_weapon_slot == logical_slot if is_weapon_slot else selected_quick_slot == logical_slot
	var outline: Color = tint if selected else Color("53636B")
	_draw_card(Rect2(position, Vector2(slot_size, slot_size)), outline, 0.96)
	var slot_labels: Array[String] = ["1", "2", "3", "4", "Q", "F"]
	_draw_label(font, position + Vector2(7.0, 15.0), slot_labels[index], 11, INK)
	if is_weapon_slot:
		var icon: Texture2D = weapon_one_icon if index == 0 else weapon_two_icon
		if icon != null:
			var icon_scale: float = 1.0
			if _player != null and index < _player.weapons.size() and _player.weapons[index] != null:
				icon_scale = _player.weapons[index].ui_icon_scale
			_draw_texture_contained(icon, Rect2(position + Vector2(9.0, 18.0), Vector2(slot_size - 18.0, 28.0)), icon_scale)
		else:
			draw_circle(position + Vector2(slot_size * 0.5, slot_size * 0.5), 11.0, Color(tint, 0.18))
			_draw_label(font, position + Vector2(21.0, 40.0), "武器", 9, tint)
		if selected and reload_ratio > 0.0:
			_draw_reload_overlay(position, slot_size, reload_ratio)
		return
	var record: Dictionary = _quick_slot_record(logical_slot)
	var count: int = int(record.get("count", 0))
	_draw_item_icon(position + Vector2(slot_size * 0.5, slot_size * 0.5), record, tint, 15.0)
	_draw_label(font, position + Vector2(slot_size - 20.0, slot_size - 8.0), str(count), 11, tint if count > 0 else MUTED)

func _quick_slot_record(logical_slot: int) -> Dictionary:
	if _player == null or not is_instance_valid(_player):
		return {}
	match logical_slot:
		2:
			return _player.get_inventory_record("healing")
		3:
			return _player.get_inventory_record("consumable")
		4:
			return _player.get_inventory_record("throwable_1")
		5:
			return _player.get_inventory_record("throwable_2")
		_:
			return {}

func _quickbar_logical_slot(visual_index: int) -> int:
	var visual_order: Array[int] = [0, 1, 4, 5, 2, 3]
	if visual_index < 0 or visual_index >= visual_order.size():
		return -1
	return visual_order[visual_index]

func _draw_reload_overlay(position: Vector2, slot_size: float, ratio: float) -> void:
	var center: Vector2 = position + Vector2(slot_size * 0.5, slot_size * 0.5)
	var points: PackedVector2Array = PackedVector2Array([center])
	for index in 25:
		var angle: float = -PI * 0.5 + TAU * ratio * float(index) / 24.0
		points.append(center + Vector2.from_angle(angle) * (slot_size * 0.52))
	draw_colored_polygon(points, Color(0.18, 0.2, 0.22, 0.72))
	draw_arc(center, slot_size * 0.46, -PI * 0.5, -PI * 0.5 + TAU * ratio, 24, Color(0.75, 0.78, 0.8, 0.95), 3.0)

func _draw_inventory(font: Font, screen: Vector2) -> void:
	_refresh_inventory_view_from_player()
	draw_rect(Rect2(Vector2.ZERO, screen), Color(0.01, 0.02, 0.025, 0.84), true)
	_draw_overlay_grid(screen)
	var panel: Rect2 = _inventory_panel(screen)
	_draw_frame(panel, MINT)
	_draw_label(font, panel.position + Vector2(24.0, 36.0), "LOADOUT  //  现场背包", 22, INK)
	_draw_label(font, panel.position + Vector2(25.0, 58.0), "拖动图标装备或卸下  ·  Tab 返回任务", 11, MUTED)
	var equipment_panel: Rect2 = _inventory_equipment_panel(screen)
	var backpack_panel: Rect2 = _inventory_backpack_panel(screen)
	_draw_card(equipment_panel, MINT, 0.68)
	_draw_card(backpack_panel, AMBER, 0.68)
	_draw_label(font, equipment_panel.position + Vector2(18.0, 30.0), "装备槽位", 16, MINT)
	_draw_label(font, backpack_panel.position + Vector2(18.0, 30.0), "背包槽位  //  4 × 3", 16, AMBER)

	_draw_equipment_slot(font, _inventory_rect(screen, "armor_head"), "头部", _player.get_inventory_record("armor_head") if _player != null else {}, BLUE)
	_draw_equipment_slot(font, _inventory_rect(screen, "armor_hands"), "手部", _player.get_inventory_record("armor_hands") if _player != null else {}, BLUE)
	_draw_equipment_slot(font, _inventory_rect(screen, "armor_body"), "身体", _player.get_inventory_record("armor_body") if _player != null else {}, BLUE)
	_draw_equipment_slot(font, _inventory_rect(screen, "weapon_1"), "武器 1", _player.get_inventory_record("weapon_1") if _player != null else {}, AMBER)
	_draw_equipment_slot(font, _inventory_rect(screen, "weapon_2"), "武器 2", _player.get_inventory_record("weapon_2") if _player != null else {}, BLUE)
	_draw_equipment_slot(font, _inventory_rect(screen, "healing"), "回复血瓶  Q", _player.get_inventory_record("healing") if _player != null else {}, RED)
	_draw_equipment_slot(font, _inventory_rect(screen, "consumable"), "消耗品  F", _player.get_inventory_record("consumable") if _player != null else {}, PURPLE)
	_draw_equipment_slot(font, _inventory_rect(screen, "throwable_1"), "投掷物 1", _player.get_inventory_record("throwable_1") if _player != null else {}, AMBER)
	_draw_equipment_slot(font, _inventory_rect(screen, "throwable_2"), "投掷物 2", _player.get_inventory_record("throwable_2") if _player != null else {}, PURPLE)
	for index in 12:
		var bag_record: Dictionary = _player.get_inventory_record("backpack_%d" % index) if _player != null else {}
		_draw_backpack_slot(font, _inventory_rect(screen, "backpack_%d" % index), index, bag_record, Color("C47AE8"))
	_draw_label(font, panel.position + Vector2(24.0, panel.size.y - 18.0), "悬停查看名称  ·  空槽保留位置  ·  物品不会因关闭背包而丢失", 11, MUTED)
	var hover_slot: String = _inventory_hit_test(get_viewport().get_mouse_position())
	if hover_slot != "" and _player != null:
		var hover_record: Dictionary = _player.get_inventory_record(hover_slot)
		if not hover_record.is_empty() and int(hover_record.get("count", 0)) > 0:
			_draw_inventory_tooltip(font, get_viewport().get_mouse_position(), hover_record)

func _draw_inventory_slot(font: Font, position: Vector2, slot_name: String, record: Dictionary, tint: Color) -> void:
	_draw_card(Rect2(position, Vector2(340.0, 66.0)), Color("53636B"), 0.76)
	_draw_item_icon(position + Vector2(28.0, 33.0), record, tint, 17.0)
	_draw_label(font, position + Vector2(54.0, 27.0), slot_name, 11, MUTED)
	var value: String = "空槽" if _is_empty_inventory_record(record) else "×%d" % int(record.get("count", 0))
	_draw_label(font, position + Vector2(54.0, 47.0), value, 12, tint)

func _draw_equipment_slot(font: Font, rect: Rect2, slot_name: String, record: Dictionary, tint: Color) -> void:
	_draw_card(rect, tint, 0.72)
	_draw_label(font, rect.position + Vector2(10.0, -8.0), slot_name, 11, tint)
	_draw_item_icon(rect.position + rect.size * 0.5, record, tint, minf(rect.size.x, rect.size.y) * 0.32)
	if not _is_empty_inventory_record(record):
		var count: int = int(record.get("count", 0))
		if count > 1:
			_draw_label(font, rect.position + Vector2(rect.size.x - 24.0, rect.size.y - 10.0), str(count), 11, tint)

func _draw_backpack_slot(font: Font, rect: Rect2, index: int, record: Dictionary, tint: Color) -> void:
	_draw_card(rect, tint, 0.62)
	_draw_label(font, rect.position + Vector2(10.0, 18.0), str(index + 1), 11, INK)
	_draw_item_icon(rect.position + rect.size * 0.5, record, tint, minf(rect.size.x, rect.size.y) * 0.34)
	if not _is_empty_inventory_record(record):
		_draw_label(font, rect.position + Vector2(rect.size.x - 28.0, rect.size.y - 10.0), str(int(record.get("count", 0))), 11, tint)

func _draw_compact_inventory_slot(font: Font, position: Vector2, index: int, record: Dictionary, tint: Color) -> void:
	var rect: Rect2 = Rect2(position, Vector2(78.0, 60.0))
	_draw_card(rect, Color("53636B"), 0.76)
	_draw_label(font, position + Vector2(7.0, 14.0), str(index + 1), 10, INK)
	_draw_item_icon(position + Vector2(39.0, 34.0), record, tint, 18.0)
	if not record.is_empty():
		_draw_label(font, position + Vector2(56.0, 53.0), str(int(record.get("count", 0))), 10, tint)

func _draw_item_icon(center: Vector2, record: Dictionary, tint: Color, size: float) -> void:
	if _is_empty_inventory_record(record):
		var empty_rect: Rect2 = Rect2(center - Vector2(size * 0.58, size * 0.58), Vector2(size * 1.16, size * 1.16))
		draw_rect(empty_rect, Color(tint, 0.08), true)
		draw_rect(empty_rect, Color(tint, 0.45), false, 1.5)
		draw_line(empty_rect.position + Vector2(4.0, 4.0), empty_rect.end - Vector2(4.0, 4.0), Color(tint, 0.42), 1.0)
		draw_line(Vector2(empty_rect.end.x - 4.0, empty_rect.position.y + 4.0), Vector2(empty_rect.position.x + 4.0, empty_rect.end.y - 4.0), Color(tint, 0.42), 1.0)
		return
	var icon: Texture2D = record.get("icon") as Texture2D
	if icon != null:
		var icon_scale: float = 1.0
		var weapon_data: WeaponData = record.get("data") as WeaponData
		if weapon_data != null:
			icon_scale = weapon_data.ui_icon_scale
		_draw_texture_contained(icon, Rect2(center - Vector2(size, size), Vector2(size * 2.0, size * 2.0)), icon_scale)
		return
	var item_key: String = String(record.get("key", ""))
	var item_kind: String = String(record.get("kind", ""))
	var item_color: Color = tint
	if item_key == "ammo_box":
		item_color = BLUE
		draw_rect(Rect2(center - Vector2(size * 0.7, size * 0.55), Vector2(size * 1.4, size * 1.1)), Color(item_color, 0.25), true)
		draw_rect(Rect2(center - Vector2(size * 0.7, size * 0.55), Vector2(size * 1.4, size * 1.1)), item_color, false, 2.0)
		draw_line(center - Vector2(size * 0.45, 0.0), center + Vector2(size * 0.45, 0.0), item_color, 2.0)
	elif item_key == "adrenaline":
		item_color = AMBER
		var lightning: PackedVector2Array = PackedVector2Array([center + Vector2(-4.0, -size), center + Vector2(size * 0.15, -2.0), center + Vector2(-1.0, -2.0), center + Vector2(5.0, size), center + Vector2(-size * 0.2, 3.0), center + Vector2(1.0, 3.0)])
		draw_colored_polygon(lightning, item_color)
	elif item_kind == "healing" or item_key == "medkit":
		item_color = RED
		draw_circle(center, size * 0.72, Color(item_color, 0.25))
		draw_rect(Rect2(center - Vector2(3.0, size * 0.5), Vector2(6.0, size)), item_color, true)
		draw_rect(Rect2(center - Vector2(size * 0.5, 3.0), Vector2(size, 6.0)), item_color, true)
	else:
		draw_circle(center, size * 0.7, Color(item_color, 0.22))
		draw_circle(center, size * 0.42, item_color)
		draw_arc(center, size * 0.85, 0.0, TAU, 18, Color(item_color, 0.8), 2.0)

func _draw_texture_contained(texture: Texture2D, box: Rect2, scale: float = 1.0) -> void:
	if texture == null:
		return
	var texture_size: Vector2 = texture.get_size()
	if texture_size.x <= 0.0 or texture_size.y <= 0.0:
		return
	var fit_scale: float = minf(box.size.x / texture_size.x, box.size.y / texture_size.y) * maxf(scale, 0.01)
	var draw_size: Vector2 = texture_size * fit_scale
	var draw_rect: Rect2 = Rect2(box.position + (box.size - draw_size) * 0.5, draw_size)
	draw_texture_rect(texture, draw_rect, false, Color.WHITE)

func _is_empty_inventory_record(record: Dictionary) -> bool:
	return record.is_empty() or int(record.get("count", 0)) <= 0

func _draw_inventory_tooltip(font: Font, mouse_position: Vector2, record: Dictionary) -> void:
	var label: String = "%s  ×%d" % [String(record.get("name", "物品")), int(record.get("count", 0))]
	var tooltip_position: Vector2 = mouse_position + Vector2(14.0, 14.0)
	var tooltip_rect: Rect2 = Rect2(tooltip_position, Vector2(170.0, 32.0))
	var screen: Vector2 = get_viewport_rect().size
	if tooltip_rect.end.x > screen.x - 8.0:
		tooltip_position.x = mouse_position.x - tooltip_rect.size.x - 14.0
	if tooltip_rect.end.y > screen.y - 8.0:
		tooltip_position.y = mouse_position.y - tooltip_rect.size.y - 14.0
	tooltip_rect.position = tooltip_position
	_draw_card(tooltip_rect, MINT, 0.98)
	_draw_label(font, tooltip_position + Vector2(10.0, 21.0), label, 11, INK)

func _inventory_record_label(record: Dictionary) -> String:
	if record.is_empty():
		return "空"
	var name: String = String(record.get("name", "未知物品"))
	var count: int = int(record.get("count", 0))
	return "%s ×%d" % [name, count]

func _combat_slot_hit_test(point: Vector2) -> int:
	var screen: Vector2 = get_viewport_rect().size
	var slot_size: float = 56.0
	var gap: float = 8.0
	var total_width: float = slot_size * 6.0 + gap * 5.0
	var start_x: float = (screen.x - total_width) * 0.5
	var y: float = screen.y - 156.0
	for index in 6:
		var rect: Rect2 = Rect2(Vector2(start_x + index * (slot_size + gap), y), Vector2(slot_size, slot_size))
		if rect.has_point(point):
			return index
	return -1

func _inventory_hit_test(point: Vector2) -> String:
	var screen: Vector2 = get_viewport_rect().size
	var equipment_slots: Array[String] = ["armor_head", "armor_hands", "armor_body", "weapon_1", "weapon_2", "healing", "consumable", "throwable_1", "throwable_2"]
	for slot_id in equipment_slots:
		if _inventory_rect(screen, slot_id).has_point(point):
			return slot_id
	for index in 12:
		if _inventory_rect(screen, "backpack_%d" % index).has_point(point):
			return "backpack_%d" % index
	return ""

func _inventory_rect(screen: Vector2, slot_id: String) -> Rect2:
	var equipment_panel: Rect2 = _inventory_equipment_panel(screen)
	var left_x: float = equipment_panel.position.x + 20.0
	var top_y: float = equipment_panel.position.y + 68.0
	var armor_size: Vector2 = Vector2(150.0, 92.0)
	var armor_index: int = ["armor_head", "armor_hands", "armor_body"].find(slot_id)
	if armor_index >= 0:
		return Rect2(Vector2(left_x + armor_index * 170.0, top_y), armor_size)
	if slot_id == "weapon_1" or slot_id == "weapon_2":
		var weapon_column: int = 0 if slot_id == "weapon_1" else 1
		return Rect2(Vector2(left_x + weapon_column * 260.0, top_y + 148.0), Vector2(240.0, 98.0))
	var item_slots: Array[String] = ["healing", "consumable", "throwable_1", "throwable_2"]
	var item_index: int = item_slots.find(slot_id)
	if item_index >= 0:
		return Rect2(Vector2(left_x + item_index * 120.0, top_y + 296.0), Vector2(108.0, 98.0))
	var bag_index: int = int(slot_id.trim_prefix("backpack_")) if slot_id.begins_with("backpack_") else -1
	if bag_index >= 0 and bag_index < 12:
		var backpack_panel: Rect2 = _inventory_backpack_panel(screen)
		var bag_row: int = floori(float(bag_index) / 4.0)
		var bag_column: int = bag_index % 4
		return Rect2(backpack_panel.position + Vector2(20.0 + bag_column * 132.0, 68.0 + bag_row * 120.0), Vector2(120.0, 108.0))
	return Rect2()

func _inventory_panel(screen: Vector2) -> Rect2:
	var panel_size: Vector2 = Vector2(minf(screen.x - 64.0, 1180.0), minf(screen.y - 64.0, 640.0))
	return Rect2((screen - panel_size) * 0.5, panel_size)

func _inventory_equipment_panel(screen: Vector2) -> Rect2:
	var panel: Rect2 = _inventory_panel(screen)
	return Rect2(panel.position + Vector2(20.0, 78.0), Vector2(540.0, 492.0))

func _inventory_backpack_panel(screen: Vector2) -> Rect2:
	var panel: Rect2 = _inventory_panel(screen)
	return Rect2(panel.position + Vector2(580.0, 78.0), Vector2(580.0, 492.0))

func _draw_map(font: Font, screen: Vector2) -> void:
	draw_rect(Rect2(Vector2.ZERO, screen), Color(0.01, 0.02, 0.025, 0.88), true)
	_draw_overlay_grid(screen)
	var panel: Rect2 = Rect2(36.0, 34.0, screen.x - 72.0, screen.y - 68.0)
	_draw_frame(panel, MINT)
	_draw_label(font, panel.position + Vector2(24.0, 34.0), "MAP  //  当前区域", 22, INK)
	_draw_label(font, panel.position + Vector2(24.0, 56.0), map_label, 11, MINT)
	var map_rect: Rect2 = Rect2(panel.position + Vector2(24.0, 82.0), Vector2(panel.size.x - 344.0, panel.size.y - 122.0))
	var info_rect: Rect2 = Rect2(panel.position + Vector2(panel.size.x - 296.0, 82.0), Vector2(272.0, panel.size.y - 122.0))
	_draw_card(map_rect, MINT, 0.68)
	_draw_card(info_rect, AMBER, 0.68)
	_draw_map_world(font, map_rect)
	_draw_map_info(font, info_rect)
	_draw_label(font, panel.position + Vector2(24.0, panel.size.y - 16.0), "M 关闭地图  ·  地图仅显示已记录的当前区域结构", 11, MUTED)

func _draw_map_world(font: Font, map_rect: Rect2) -> void:
	if _map_manager == null:
		_draw_label(font, map_rect.position + Vector2(24.0, 34.0), "区域数据不可用", 13, RED)
		return
	var active_map_value: Variant = _map_manager.get("active_map")
	var active_map: Node = active_map_value as Node
	if active_map == null:
		_draw_label(font, map_rect.position + Vector2(24.0, 34.0), "MAP DATA UNAVAILABLE", 13, RED)
		return
	var world_size_value: Variant = active_map.get("map_size")
	var world_size: Vector2 = world_size_value as Vector2
	var surface_nodes: Array[Node] = active_map.find_children("*", "MapSurface", true, false)
	if not surface_nodes.is_empty():
		var surface: Node = surface_nodes[0]
		if surface != null:
			var corridor_rects_value: Variant = surface.get("corridor_rects")
			var room_rects_value: Variant = surface.get("room_rects")
			for corridor in corridor_rects_value as Array:
				draw_rect(_map_world_rect(corridor, map_rect, world_size), Color("315555", 0.72), true)
			for room in room_rects_value as Array:
				draw_rect(_map_world_rect(room, map_rect, world_size), Color("24383A", 0.78), true)
				draw_rect(_map_world_rect(room, map_rect, world_size), Color("6C938E", 0.66), false, 1.0)
	var wall_nodes: Array[Node] = active_map.find_children("*", "Wall", true, false)
	for wall_node in wall_nodes:
		var wall: Node = wall_node
		if wall != null:
			var wall_size: Vector2 = wall.get("size") as Vector2
			var wall_rect: Rect2 = Rect2(wall.global_position - wall_size * 0.5, wall_size)
			draw_rect(_map_world_rect(wall_rect, map_rect, world_size), Color("91A3A0", 0.94), true)
	var door_nodes: Array[Node] = active_map.find_children("*", "MapDoor", true, false)
	for door_node in door_nodes:
		var door: Node = door_node
		if door != null:
			var door_size: Vector2 = door.get("size") as Vector2
			var door_rect: Rect2 = Rect2(door.global_position - door_size * 0.5, door_size)
			var door_opened: bool = bool(door.get("opened"))
			var door_locked: bool = bool(door.get("locked"))
			var door_color: Color = MINT if door_opened else RED if door_locked else AMBER
			draw_rect(_map_world_rect(door_rect, map_rect, world_size), door_color, true)
	var prop_nodes: Array[Node] = active_map.find_children("*", "MapProp", true, false)
	for prop_node in prop_nodes:
		var prop: Node = prop_node
		if prop != null:
			var prop_size: Vector2 = prop.get("size") as Vector2
			var prop_rect: Rect2 = Rect2(prop.global_position - prop_size * 0.5, prop_size)
			draw_rect(_map_world_rect(prop_rect, map_rect, world_size), Color("B77E5D", 0.72), true)
	var light_nodes: Array[Node] = active_map.find_children("*", "MapLight", true, false)
	for light_node in light_nodes:
		var map_light: Node = light_node
		if map_light != null:
			var light_point: Vector2 = _map_world_point(map_light.global_position, map_rect, world_size)
			var light_scale: float = float(map_light.get("texture_scale"))
			var light_color: Color = map_light.get("light_color") as Color
			draw_circle(light_point, 8.0 * light_scale, Color(light_color, 0.12))
			draw_circle(light_point, 2.5, light_color)
	for marker_type in ["power", "respawn", "exit", "boss_spawn", "enemy_spawn", "pickup"]:
		var marker_color: Color = _map_marker_color(marker_type)
		var markers_value: Variant = active_map.call("get_markers", marker_type)
		for marker in markers_value as Array:
			var marker_point: Vector2 = _map_world_point(marker.global_position, map_rect, world_size)
			draw_circle(marker_point, 5.0 if marker_type != "power" else 7.0, marker_color)
			if marker_type == "power":
				draw_arc(marker_point, 11.0, 0.0, TAU, 16, Color(marker_color, 0.7), 1.0)
	if _player != null and is_instance_valid(_player):
		var player_point: Vector2 = _map_world_point(_player.global_position, map_rect, world_size)
		draw_circle(player_point, 8.0, MINT)
		draw_circle(player_point, 13.0, Color(MINT, 0.55), false, 1.5)
	_draw_label(font, map_rect.position + Vector2(14.0, 22.0), "区域结构", 11, MUTED)

func _draw_map_info(font: Font, info_rect: Rect2) -> void:
	_draw_label(font, info_rect.position + Vector2(18.0, 30.0), "OBJECTIVES", 15, INK)
	draw_line(info_rect.position + Vector2(18.0, 42.0), info_rect.position + Vector2(info_rect.size.x - 18.0, 42.0), Color(AMBER, 0.55), 1.0)
	_draw_map_info_row(font, info_rect, 72.0, "POWER", "%d / %d" % [power_fixed, power_total], MINT)
	_draw_map_info_row(font, info_rect, 122.0, "RESPAWN", "已标记", BLUE)
	_draw_map_info_row(font, info_rect, 172.0, "BOSS", "沉睡" if boss_health <= 0.0 else "已唤醒", RED if boss_health > 0.0 else MUTED)
	_draw_map_info_row(font, info_rect, 222.0, "EXTRACTION", "锁定", RED)
	draw_line(info_rect.position + Vector2(18.0, 270.0), info_rect.position + Vector2(info_rect.size.x - 18.0, 270.0), Color("526A6A", 0.6), 1.0)
	_draw_label(font, info_rect.position + Vector2(18.0, 300.0), "图例", 13, INK)
	_draw_map_legend_row(font, info_rect, 326.0, "玩家", MINT)
	_draw_map_legend_row(font, info_rect, 354.0, "电源", MINT)
	_draw_map_legend_row(font, info_rect, 382.0, "安全屋", BLUE)
	_draw_map_legend_row(font, info_rect, 410.0, "出口 / Boss", RED)

func _draw_map_info_row(font: Font, rect: Rect2, y: float, label: String, value: String, tint: Color) -> void:
	draw_circle(rect.position + Vector2(22.0, y - 5.0), 4.0, tint)
	_draw_label(font, rect.position + Vector2(36.0, y), label, 11, MUTED)
	_draw_label(font, rect.position + Vector2(rect.size.x - 104.0, y), value, 11, tint)

func _draw_map_legend_row(font: Font, rect: Rect2, y: float, label: String, tint: Color) -> void:
	draw_circle(rect.position + Vector2(24.0, y - 4.0), 4.0, tint)
	_draw_label(font, rect.position + Vector2(38.0, y), label, 11, MUTED)

func _map_world_point(world_point: Vector2, map_rect: Rect2, world_size: Vector2) -> Vector2:
	var map_scale: float = minf((map_rect.size.x - 20.0) / maxf(world_size.x, 1.0), (map_rect.size.y - 20.0) / maxf(world_size.y, 1.0))
	var drawn_size: Vector2 = world_size * map_scale
	var origin: Vector2 = map_rect.position + (map_rect.size - drawn_size) * 0.5
	return origin + world_point * map_scale

func _map_world_rect(world_rect: Rect2, map_rect: Rect2, world_size: Vector2) -> Rect2:
	var top_left: Vector2 = _map_world_point(world_rect.position, map_rect, world_size)
	var bottom_right: Vector2 = _map_world_point(world_rect.end, map_rect, world_size)
	return Rect2(top_left, bottom_right - top_left)

func _map_marker_color(marker_type: String) -> Color:
	match marker_type:
		"power":
			return MINT
		"respawn":
			return BLUE
		"exit":
			return RED
		"boss_spawn":
			return RED
		"enemy_spawn":
			return Color("D06A78")
		"pickup":
			return AMBER
		_:
			return MUTED

func _draw_screen_overlay(font: Font, screen: Vector2) -> void:
	draw_rect(Rect2(Vector2.ZERO, screen), Color(0.01, 0.018, 0.022, 0.72), true)
	_draw_overlay_grid(screen)
	var frame: Rect2 = Rect2(22.0, 22.0, screen.x - 44.0, screen.y - 44.0)
	_draw_frame(frame, MINT if screen_phase == "菜单" else RED if screen_phase == "失败" else AMBER)
	var panel: Rect2 = Rect2(68.0, 88.0, screen.x - 136.0, screen.y - 176.0)
	var accent: Color = MINT if screen_phase == "菜单" else RED if screen_phase == "失败" else AMBER
	var title: String = "PRISON"
	var subtitle: String = "SILENT ESCAPE  //  FACILITY 07"
	var action: String = "开始任务  ·  Enter"
	if screen_phase == "失败":
		title = "RUN FAILED"
		subtitle = "本次携带物资已丢失，永久成长仍然保留"
		action = "重新开始  ·  Enter"
	elif screen_phase == "结算":
		title = "EXTRACTION"
		subtitle = "你带着战利品离开了监狱"
		action = "继续下一局  ·  Enter"
	_draw_label(font, panel.position + Vector2(38.0, 36.0), "RUN CONTROL  //  BUILD 0.1", 11, accent)
	_draw_label(font, panel.position + Vector2(38.0, 116.0), title, 58, INK)
	_draw_label(font, panel.position + Vector2(44.0, 148.0), subtitle, 13, MUTED)
	draw_line(panel.position + Vector2(40.0, 174.0), panel.position + Vector2(420.0, 174.0), Color(accent, 0.7), 2.0)
	_draw_label(font, panel.position + Vector2(42.0, 206.0), "恢复电力，保持安静，找到撤离点", 14, INK)

	var brief_rect: Rect2 = Rect2(panel.position + Vector2(40.0, 246.0), Vector2(350.0, 142.0))
	_draw_card(brief_rect, accent, 0.72)
	_draw_label(font, brief_rect.position + Vector2(18.0, 27.0), "任务简报", 14, INK)
	_draw_label(font, brief_rect.position + Vector2(18.0, 58.0), "01  修复三处电源", 12, AMBER)
	_draw_label(font, brief_rect.position + Vector2(18.0, 84.0), "02  控制噪声，避免过早唤醒守卫者", 11, MUTED)
	_draw_label(font, brief_rect.position + Vector2(18.0, 110.0), "03  击败守卫者并抵达撤离门", 11, MUTED)

	var controls_rect: Rect2 = Rect2(panel.position + Vector2(430.0, 246.0), Vector2(420.0, 142.0))
	_draw_card(controls_rect, Color("60747B"), 0.72)
	_draw_label(font, controls_rect.position + Vector2(18.0, 27.0), "操作协议", 14, INK)
	_draw_label(font, controls_rect.position + Vector2(18.0, 58.0), "WASD 移动   Shift 奔跑   Space 冲刺", 11, MUTED)
	_draw_label(font, controls_rect.position + Vector2(18.0, 84.0), "鼠标左键 射击/投掷   右键 瞄准/格挡", 11, MUTED)
	_draw_label(font, controls_rect.position + Vector2(18.0, 110.0), "1/2 武器   3/4 投掷物   Q/F 物品", 11, MUTED)

	var action_rect: Rect2 = _screen_action_rect(screen)
	var action_accent: Color = INK if action_rect.has_point(get_viewport().get_mouse_position()) else accent
	_draw_card(action_rect, action_accent, 0.96)
	_draw_label(font, action_rect.position + Vector2(190.0, 37.0), action, 16, action_accent)
	_draw_label(font, panel.position + Vector2(42.0, panel.size.y - 12.0), "Tab 背包   T 手电筒   E 互动   //  进入后可查看地图区域", 11, MUTED)

func _screen_action_rect(screen: Vector2) -> Rect2:
	return Rect2(Vector2(screen.x * 0.5 - 252.0, screen.y - 132.0), Vector2(504.0, 56.0))

func _draw_overlay_grid(screen: Vector2) -> void:
	var grid_color: Color = Color("5A7475", 0.09)
	for x in range(0, int(screen.x) + 1, 48):
		draw_line(Vector2(x, 0.0), Vector2(x, screen.y), grid_color, 1.0)
	for y in range(0, int(screen.y) + 1, 48):
		draw_line(Vector2(0.0, y), Vector2(screen.x, y), grid_color, 1.0)
	draw_circle(Vector2(screen.x * 0.78, screen.y * 0.32), 170.0, Color("B44A3C", 0.035))
	draw_circle(Vector2(screen.x * 0.25, screen.y * 0.68), 210.0, Color("2AB7A1", 0.035))

func _draw_frame(rect: Rect2, accent: Color) -> void:
	draw_rect(rect, Color("081014", 0.25), false, 2.0)
	draw_rect(rect.grow(-7.0), Color(accent, 0.28), false, 1.0)
	var length: float = 34.0
	draw_line(rect.position + Vector2(0.0, 10.0), rect.position + Vector2(length, 10.0), accent, 2.0)
	draw_line(rect.position + Vector2(10.0, 0.0), rect.position + Vector2(10.0, length), accent, 2.0)
	draw_line(Vector2(rect.end.x - length, rect.position.y + 10.0), Vector2(rect.end.x - 10.0, rect.position.y + 10.0), accent, 2.0)
	draw_line(Vector2(rect.end.x - 10.0, rect.end.y - length), Vector2(rect.end.x - 10.0, rect.end.y - 10.0), accent, 2.0)
	draw_line(Vector2(rect.position.x + length, rect.end.y - 10.0), Vector2(rect.position.x + 10.0, rect.end.y - 10.0), accent, 2.0)
	draw_line(Vector2(rect.position.x + 10.0, rect.end.y - length), Vector2(rect.position.x + 10.0, rect.end.y - 10.0), accent, 2.0)

func _draw_section(font: Font, position: Vector2, label: String) -> void:
	_draw_label(font, position, label, 13, MINT)
	draw_line(position + Vector2(0.0, 8.0), position + Vector2(330.0, 8.0), Color("3C5660"), 1.0)

func _draw_card(rect: Rect2, accent: Color, alpha: float) -> void:
	draw_rect(rect.grow(5.0), Color(0.0, 0.0, 0.0, alpha * 0.42), true)
	draw_rect(rect, Color(PANEL, alpha), true)
	draw_rect(rect, Color(accent, alpha), false, 1.5)
	draw_rect(rect.grow(-4.0), Color(accent, alpha * 0.22), false, 1.0)
	var corner: float = 18.0
	draw_line(rect.position + Vector2(0.0, 6.0), rect.position + Vector2(corner, 6.0), accent, 2.0)
	draw_line(rect.position + Vector2(6.0, 0.0), rect.position + Vector2(6.0, corner), accent, 2.0)
	draw_line(Vector2(rect.end.x - corner, rect.position.y + 6.0), Vector2(rect.end.x, rect.position.y + 6.0), accent, 2.0)
	draw_line(Vector2(rect.end.x - 6.0, rect.position.y), Vector2(rect.end.x - 6.0, rect.position.y + corner), accent, 2.0)
	draw_line(Vector2(rect.position.x, rect.end.y - 6.0), Vector2(rect.position.x + corner, rect.end.y - 6.0), Color(accent, 0.62), 1.0)
	draw_line(Vector2(rect.end.x - corner, rect.end.y - 6.0), Vector2(rect.end.x, rect.end.y - 6.0), Color(accent, 0.62), 1.0)

func _draw_label(font: Font, position: Vector2, label: String, size: int, color: Color) -> void:
	draw_string(font, position, label, HORIZONTAL_ALIGNMENT_LEFT, -1.0, size, color)

func _draw_bar(rect: Rect2, ratio: float, fill_color: Color) -> void:
	draw_rect(rect, Color("273842"), true)
	draw_rect(Rect2(rect.position, Vector2(rect.size.x * clampf(ratio, 0.0, 1.0), rect.size.y)), fill_color, true)
	draw_rect(rect, Color("8CA7A8"), false, 1.0)

func _noise_label(noise_total: float) -> String:
	if noise_total <= 0.0:
		return "静默"
	if noise_total <= 50.0:
		return "低鸣"
	if noise_total <= 120.0:
		return "警戒"
	return "危险"

func _weapon_label(index: int) -> String:
	if _player == null or index >= _player.weapons.size():
		return "空"
	var weapon: WeaponData = _player.weapons[index]
	var name: String = _translate_weapon_name(weapon.weapon_name)
	return "%s  %d / %d" % [name, _player.current_ammo if index == _player.current_weapon_index else weapon.mag_size, weapon.mag_size]

func _translate_weapon_name(value: String) -> String:
	var text: String = value
	text = text.replace("Pistol", "手枪").replace("Shotgun", "霰弹枪").replace("Crowbar", "撬棍")
	text = text.replace("Fine", "精良").replace("Rare", "稀有").replace("Epic", "史诗").replace("Legendary", "传说").replace("Common", "普通")
	return text

func _translate_state(value: String) -> String:
	match value.to_lower():
		"idle":
			return "待机"
		"move":
			return "移动"
		"dash":
			return "冲刺"
		"parry":
			return "格挡"
		_:
			return value

func _translate_boss(value: String) -> String:
	var text: String = value
	text = text.replace("SLEEPING", "沉睡").replace("sleeping", "沉睡")
	return text

func _translate_throwables(value: String) -> String:
	return value.replace("F", "信号弹 ").replace("S", "烟雾弹 ").replace("G", "手雷 ").replace("M", "地雷 ")

func _translate_event(value: String) -> String:
	var text: String = value
	var replacements: Dictionary = {
		"WASD move, Shift run, Space dash, LMB fire": "准备行动：移动、射击或打开背包",
		"Demo ready": "系统就绪",
		"Run started": "任务开始：恢复电力并撤离",
		"YOU DIED": "任务失败",
		"WARDEN DEFEATED": "守卫者已击败",
		"All power restored": "全部电力已恢复",
		"RespawnPoint": "复活点",
		"discovered": "已发现",
		"resupply and regroup here": "在此补给和整备",
		"heard the noise": "听到了噪声",
		"Perfect parry!": "完美格挡！",
		"Fired": "开火",
		"Switched weapon": "切换武器",
		"Dash": "冲刺",
		"defeated": "已击败",
		"ESCAPED": "已撤离",
		"Used / collected": "已使用 / 拾取",
		"Respawn point resupply": "复活点补给",
		"Throwable deployed": "已投掷物品",
	}
	for key in replacements:
		text = text.replace(key, replacements[key])
	return _translate_weapon_name(text)

func _on_damage_feedback(_target: Node2D, _amount: float, _position: Vector2, is_player: bool) -> void:
	if is_player:
		damage_flash_remaining = 0.22

func _on_player_parried(_attacker: Node2D) -> void:
	parry_flash_remaining = 0.28

func flash_boss_alert(duration: float = 1.4) -> void:
	boss_alert_remaining = maxf(boss_alert_remaining, duration)
	queue_redraw()
