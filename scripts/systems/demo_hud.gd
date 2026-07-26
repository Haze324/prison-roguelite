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
var inventory_open: bool = false
var inventory_drag_source: String = ""
var damage_flash_remaining: float = 0.0
var parry_flash_remaining: float = 0.0
var boss_alert_remaining: float = 0.0
var _player: Player
var screen_phase: String = "菜单"

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	_player = get_node_or_null("../../Player") as Player
	EventBus.damage_feedback.connect(_on_damage_feedback)
	EventBus.player_parried.connect(_on_player_parried)
	queue_redraw()

func _input(event: InputEvent) -> void:
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
				if inventory_open:
					inventory_drag_source = _inventory_hit_test(mouse_event.position)
				else:
					var active_slot: int = _combat_slot_hit_test(mouse_event.position)
					if active_slot >= 0 and _player != null:
						_player.select_active_slot(active_slot, true)
						get_viewport().set_input_as_handled()
			else:
				if inventory_open:
					var target_slot: String = _inventory_hit_test(mouse_event.position)
					if inventory_drag_source != "" and _player != null and target_slot != "":
						_player.move_inventory_item(inventory_drag_source, target_slot)
					inventory_drag_source = ""
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
	damage_flash_remaining = maxf(damage_flash_remaining - delta, 0.0)
	parry_flash_remaining = maxf(parry_flash_remaining - delta, 0.0)
	boss_alert_remaining = maxf(boss_alert_remaining - delta, 0.0)
	queue_redraw()

func _draw() -> void:
	var screen: Vector2 = get_viewport_rect().size
	var font: Font = ThemeDB.fallback_font
	var noise_total: float = temporary_noise + residual_noise
	if inventory_open:
		_draw_inventory(font, screen)
	elif screen_phase == "战斗":
		_draw_combat_hud(font, screen, noise_total)
	else:
		_draw_combat_hud(font, screen, noise_total)
		_draw_screen_overlay(font, screen)

func _draw_combat_hud(font: Font, screen: Vector2, noise_total: float) -> void:
	var status_rect: Rect2 = Rect2(18.0, 18.0, 370.0, 198.0)
	_draw_card(status_rect, MINT, 0.94)
	_draw_label(font, status_rect.position + Vector2(16.0, 25.0), "生还者状态", 17, INK)
	_draw_label(font, status_rect.position + Vector2(16.0, 48.0), "生命", 11, MUTED)
	_draw_bar(Rect2(status_rect.position + Vector2(64.0, 38.0), Vector2(182.0, 12.0)), health / maxf(max_health, 1.0), RED)
	_draw_label(font, status_rect.position + Vector2(254.0, 49.0), "%d / %d" % [roundi(health), roundi(max_health)], 11, INK)
	_draw_label(font, status_rect.position + Vector2(16.0, 73.0), "护甲", 11, MUTED)
	_draw_bar(Rect2(status_rect.position + Vector2(64.0, 63.0), Vector2(182.0, 12.0)), armor_durability / maxf(armor_maximum, 1), BLUE)
	_draw_label(font, status_rect.position + Vector2(254.0, 74.0), "%d / %d" % [armor_durability, armor_maximum], 11, INK)
	_draw_label(font, status_rect.position + Vector2(16.0, 99.0), "武器", 11, MUTED)
	_draw_label(font, status_rect.position + Vector2(64.0, 99.0), weapon_name, 12, AMBER)
	_draw_label(font, status_rect.position + Vector2(16.0, 124.0), "弹药", 11, MUTED)
	_draw_label(font, status_rect.position + Vector2(64.0, 124.0), "%d / %d  + %d" % [ammo, ammo_capacity, ammo_reserve], 12, MINT)
	_draw_label(font, status_rect.position + Vector2(16.0, 149.0), "回复血瓶", 11, MUTED)
	_draw_label(font, status_rect.position + Vector2(64.0, 149.0), "×%d" % medkits, 12, RED)
	_draw_label(font, status_rect.position + Vector2(150.0, 149.0), "击杀 %02d" % kills, 11, INK)
	_draw_label(font, status_rect.position + Vector2(250.0, 149.0), player_state, 11, MINT)
	_draw_label(font, status_rect.position + Vector2(16.0, 176.0), "消耗品", 11, MUTED)
	_draw_label(font, status_rect.position + Vector2(64.0, 176.0), consumable_name, 11, PURPLE)
	_draw_label(font, status_rect.position + Vector2(150.0, 176.0), "×%d" % (quick_slot_counts[1] if quick_slot_counts.size() > 1 else 0), 11, PURPLE)
	_draw_label(font, status_rect.position + Vector2(210.0, 176.0), "电源 %d / %d" % [power_fixed, power_total], 11, AMBER)
	_draw_label(font, status_rect.position + Vector2(16.0, 194.0), "硬币 %d" % coins, 11, INK)
	_draw_label(font, status_rect.position + Vector2(150.0, 194.0), "技能点 %d" % skill_points, 11, PURPLE)

	var threat_rect: Rect2 = Rect2(screen.x - 278.0, 18.0, 260.0, 184.0)
	_draw_card(threat_rect, AMBER if noise_total > 50.0 else MINT, 0.94)
	_draw_label(font, threat_rect.position + Vector2(16.0, 25.0), "威胁监测", 17, INK)
	_draw_label(font, threat_rect.position + Vector2(16.0, 49.0), "噪声总量", 11, MUTED)
	var noise_color: Color = MINT if noise_total <= 50.0 else AMBER if noise_total <= 120.0 else RED
	_draw_bar(Rect2(threat_rect.position + Vector2(16.0, 58.0), Vector2(228.0, 13.0)), noise_total / 200.0, noise_color)
	_draw_label(font, threat_rect.position + Vector2(16.0, 91.0), "临时 %.0f   残留 %.0f" % [temporary_noise, residual_noise], 11, noise_color)
	_draw_label(font, threat_rect.position + Vector2(16.0, 119.0), "守卫者", 11, MUTED)
	_draw_label(font, threat_rect.position + Vector2(78.0, 119.0), boss_text, 12, RED if boss_text != "沉睡" else MINT)
	_draw_label(font, threat_rect.position + Vector2(16.0, 151.0), "噪声达到 200 将唤醒守卫者", 10, MUTED)

	if boss_health > 0.0:
		var boss_rect: Rect2 = Rect2(screen.x * 0.5 - 250.0, 208.0, 500.0, 48.0)
		_draw_label(font, boss_rect.position, "守卫者  " + boss_text, 12, RED)
		_draw_bar(Rect2(boss_rect.position + Vector2(0.0, 15.0), Vector2(500.0, 14.0)), boss_health / maxf(boss_max_health, 1.0), RED)

	var event_rect: Rect2 = Rect2(18.0, screen.y - 78.0, screen.x - 36.0, 32.0)
	_draw_card(event_rect, Color("60747B"), 0.9)
	_draw_label(font, event_rect.position + Vector2(12.0, 21.0), "事件  /  " + event_text, 12, INK)
	_draw_label(font, Vector2(20.0, screen.y - 24.0), "WASD 移动   Shift 奔跑   空格 冲刺   鼠标左键 射击/蓄力投掷   R 换弹   鼠标右键 瞄准/格挡   1/2 武器   5/6 投掷物   Q 血瓶   F 消耗品   E 互动   Tab 背包", 11, MUTED)
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
	var is_weapon_slot: bool = index < 2
	var tint: Color = [AMBER, BLUE, RED, PURPLE, Color("E6D36A"), Color("C47AE8")][index]
	var selected: bool = current_weapon_slot == index if is_weapon_slot else selected_quick_slot == index
	var outline: Color = tint if selected else Color("53636B")
	_draw_card(Rect2(position, Vector2(slot_size, slot_size)), outline, 0.96)
	_draw_label(font, position + Vector2(7.0, 15.0), str(index + 1), 11, INK)
	if is_weapon_slot:
		var icon: Texture2D = weapon_one_icon if index == 0 else weapon_two_icon
		if icon != null:
			draw_texture_rect(icon, Rect2(position + Vector2(9.0, 18.0), Vector2(slot_size - 18.0, 28.0)), false, Color.WHITE)
		else:
			draw_circle(position + Vector2(slot_size * 0.5, slot_size * 0.5), 11.0, Color(tint, 0.18))
			_draw_label(font, position + Vector2(21.0, 40.0), "武器", 9, tint)
		if selected and reload_ratio > 0.0:
			_draw_reload_overlay(position, slot_size, reload_ratio)
		return
	var count_index: int = index - 2
	var count: int = quick_slot_counts[count_index] if count_index < quick_slot_counts.size() else 0
	var icon_center: Vector2 = position + Vector2(slot_size * 0.5, slot_size * 0.5)
	draw_circle(icon_center, 13.0, Color(tint, 0.18))
	if index == 2:
		draw_circle(icon_center, 7.0, tint)
		draw_rect(Rect2(icon_center - Vector2(2.0, 7.0), Vector2(4.0, 14.0)), INK, true)
		draw_rect(Rect2(icon_center - Vector2(7.0, 2.0), Vector2(14.0, 4.0)), INK, true)
	elif index == 3:
		_draw_label(font, icon_center + Vector2(-5.0, 5.0), "A", 12, tint)
	else:
		var throwable_index: int = index - 4
		var throwable_label: String = "?"
		if throwable_index >= 0 and throwable_index < throwable_slot_names.size():
			throwable_label = throwable_slot_names[throwable_index].substr(0, 1)
		_draw_label(font, icon_center + Vector2(-5.0, 5.0), throwable_label, 12, tint)
	_draw_label(font, position + Vector2(slot_size - 20.0, slot_size - 8.0), str(count), 11, tint if count > 0 else MUTED)

func _draw_reload_overlay(position: Vector2, slot_size: float, ratio: float) -> void:
	var center: Vector2 = position + Vector2(slot_size * 0.5, slot_size * 0.5)
	var points: PackedVector2Array = PackedVector2Array([center])
	for index in 25:
		var angle: float = -PI * 0.5 + TAU * ratio * float(index) / 24.0
		points.append(center + Vector2.from_angle(angle) * (slot_size * 0.52))
	draw_colored_polygon(points, Color(0.18, 0.2, 0.22, 0.72))
	draw_arc(center, slot_size * 0.46, -PI * 0.5, -PI * 0.5 + TAU * ratio, 24, Color(0.75, 0.78, 0.8, 0.95), 3.0)

func _draw_inventory(font: Font, screen: Vector2) -> void:
	draw_rect(Rect2(Vector2.ZERO, screen), Color(0.02, 0.04, 0.05, 0.78), true)
	var panel: Rect2 = Rect2((screen - Vector2(820.0, 680.0)) * 0.5, Vector2(820.0, 680.0))
	_draw_card(panel, MINT, 1.0)
	_draw_label(font, panel.position + Vector2(32.0, 42.0), "现场背包", 26, INK)
	_draw_label(font, panel.position + Vector2(33.0, 66.0), "暂停中  /  Tab 关闭", 11, MUTED)
	_draw_section(font, panel.position + Vector2(34.0, 104.0), "装备栏（拖动道具装备 / 卸下）")
	_draw_inventory_slot(font, panel.position + Vector2(34.0, 122.0), "头部防具", "空", BLUE)
	_draw_inventory_slot(font, panel.position + Vector2(34.0, 196.0), "手部防具", "空", BLUE)
	_draw_inventory_slot(font, panel.position + Vector2(34.0, 270.0), "身体防具", "已装备", BLUE)
	_draw_inventory_slot(font, panel.position + Vector2(34.0, 344.0), "武器 1", _weapon_label(0), AMBER)
	_draw_inventory_slot(font, panel.position + Vector2(34.0, 418.0), "武器 2", _weapon_label(1), BLUE)
	_draw_inventory_slot(font, panel.position + Vector2(34.0, 492.0), "回复血瓶  Q", "×%d" % medkits, RED)
	_draw_section(font, panel.position + Vector2(438.0, 104.0), "背包栏（拖动到装备槽）")
	_draw_inventory_slot(font, panel.position + Vector2(438.0, 122.0), "消耗品  F", "%s ×%d" % [consumable_name, quick_slot_counts[1] if quick_slot_counts.size() > 1 else 0], PURPLE)
	_draw_inventory_slot(font, panel.position + Vector2(438.0, 196.0), "投掷物 1", "%s ×%d" % [throwable_slot_names[0], quick_slot_counts[2] if quick_slot_counts.size() > 2 else 0], AMBER)
	_draw_inventory_slot(font, panel.position + Vector2(438.0, 270.0), "投掷物 2", "%s ×%d" % [throwable_slot_names[1], quick_slot_counts[3] if quick_slot_counts.size() > 3 else 0], PURPLE)
	_draw_label(font, panel.position + Vector2(438.0, 366.0), "背包物品  /  网格容量 12", 13, MINT)
	for index in 12:
		var row: int = floori(float(index) / 4.0)
		var column: int = index % 4
		var bag_position: Vector2 = panel.position + Vector2(438.0 + column * 82.0, 384.0 + row * 72.0)
		var bag_record: Dictionary = _player.get_inventory_record("backpack_%d" % index) if _player != null else {}
		_draw_compact_inventory_slot(font, bag_position, index, bag_record, Color("C47AE8"))
	_draw_label(font, panel.position + Vector2(36.0, 650.0), "硬币 %d     技能点 %d     拖拽道具可交换或放回背包" % [coins, skill_points], 13, AMBER)
	var hover_slot: String = _inventory_hit_test(get_viewport().get_mouse_position())
	if hover_slot != "" and _player != null:
		var hover_record: Dictionary = _player.get_inventory_record(hover_slot)
		if not hover_record.is_empty() and int(hover_record.get("count", 0)) > 0:
			_draw_inventory_tooltip(font, get_viewport().get_mouse_position(), hover_record)

func _draw_inventory_slot(font: Font, position: Vector2, slot_name: String, value: String, tint: Color) -> void:
	_draw_card(Rect2(position, Vector2(340.0, 66.0)), Color("53636B"), 0.76)
	draw_circle(position + Vector2(28.0, 33.0), 12.0, Color(tint, 0.22))
	draw_circle(position + Vector2(28.0, 33.0), 6.0, tint)
	_draw_label(font, position + Vector2(54.0, 27.0), slot_name, 11, MUTED)
	_draw_label(font, position + Vector2(54.0, 47.0), value, 12, tint)

func _draw_compact_inventory_slot(font: Font, position: Vector2, index: int, record: Dictionary, tint: Color) -> void:
	var rect: Rect2 = Rect2(position, Vector2(78.0, 60.0))
	_draw_card(rect, Color("53636B"), 0.76)
	_draw_label(font, position + Vector2(7.0, 14.0), str(index + 1), 10, INK)
	_draw_item_icon(position + Vector2(39.0, 34.0), record, tint, 18.0)
	if not record.is_empty():
		_draw_label(font, position + Vector2(56.0, 53.0), str(int(record.get("count", 0))), 10, tint)

func _draw_item_icon(center: Vector2, record: Dictionary, tint: Color, size: float) -> void:
	if record.is_empty():
		draw_circle(center, size * 0.35, Color(tint, 0.12))
		return
	var icon: Texture2D = record.get("icon") as Texture2D
	if icon != null:
		draw_texture_rect(icon, Rect2(center - Vector2(size, size), Vector2(size * 2.0, size * 2.0)), false, Color.WHITE)
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

func _draw_inventory_tooltip(font: Font, mouse_position: Vector2, record: Dictionary) -> void:
	var label: String = "%s  ×%d" % [String(record.get("name", "物品")), int(record.get("count", 0))]
	var tooltip_position: Vector2 = mouse_position + Vector2(14.0, 14.0)
	var tooltip_rect: Rect2 = Rect2(tooltip_position, Vector2(170.0, 32.0))
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
	var panel: Rect2 = Rect2((screen - Vector2(820.0, 680.0)) * 0.5, Vector2(820.0, 680.0))
	var left_x: float = panel.position.x + 34.0
	var right_x: float = panel.position.x + 438.0
	var left_slots: Array[String] = ["armor_head", "armor_hands", "armor_body", "weapon_1", "weapon_2", "healing"]
	for index in left_slots.size():
		var left_rect: Rect2 = Rect2(Vector2(left_x, panel.position.y + 122.0 + index * 74.0), Vector2(340.0, 66.0))
		if left_rect.has_point(point):
			return left_slots[index]
	var right_slots: Array[String] = ["consumable", "throwable_1", "throwable_2"]
	for index in right_slots.size():
		var right_y: float = 122.0 + index * 74.0
		var right_rect: Rect2 = Rect2(Vector2(right_x, panel.position.y + right_y), Vector2(340.0, 66.0))
		if right_rect.has_point(point):
			return right_slots[index]
	for index in 12:
		var bag_row: int = floori(float(index) / 4.0)
		var bag_column: int = index % 4
		var bag_rect: Rect2 = Rect2(panel.position + Vector2(438.0 + bag_column * 82.0, 384.0 + bag_row * 72.0), Vector2(78.0, 60.0))
		if bag_rect.has_point(point):
			return "backpack_%d" % index
	return ""

func _inventory_rect(panel: Rect2, slot_id: String) -> Rect2:
	var left_slots: Array[String] = ["armor_head", "armor_hands", "armor_body", "weapon_1", "weapon_2", "healing"]
	var left_index: int = left_slots.find(slot_id)
	if left_index >= 0:
		return Rect2(panel.position + Vector2(34.0, 122.0 + left_index * 74.0), Vector2(340.0, 66.0))
	var right_slots: Array[String] = ["consumable", "throwable_1", "throwable_2"]
	var right_index: int = right_slots.find(slot_id)
	if right_index >= 0:
		return Rect2(panel.position + Vector2(438.0, 122.0 + right_index * 74.0), Vector2(340.0, 66.0))
	var bag_index: int = int(slot_id.trim_prefix("backpack_")) if slot_id.begins_with("backpack_") else -1
	if bag_index >= 0 and bag_index < 12:
		var bag_row: int = floori(float(bag_index) / 4.0)
		var bag_column: int = bag_index % 4
		return Rect2(panel.position + Vector2(438.0 + bag_column * 82.0, 384.0 + bag_row * 72.0), Vector2(78.0, 60.0))
	return Rect2()

func _draw_screen_overlay(font: Font, screen: Vector2) -> void:
	draw_rect(Rect2(Vector2.ZERO, screen), Color(0.02, 0.035, 0.045, 0.82), true)
	var panel: Rect2 = Rect2((screen - Vector2(720.0, 420.0)) * 0.5, Vector2(720.0, 420.0))
	_draw_card(panel, MINT if screen_phase == "菜单" else RED if screen_phase == "失败" else AMBER, 1.0)
	draw_line(panel.position + Vector2(40.0, 116.0), panel.position + Vector2(680.0, 116.0), Color("3C5660"), 2.0)
	var title: String = "监狱：静默越狱"
	var subtitle: String = "恢复电力，保持安静，找到撤离点"
	var action: String = "按回车进入关卡"
	var tint: Color = MINT
	if screen_phase == "失败":
		title = "任务失败"
		subtitle = "本次携带物资已丢失，永久成长仍然保留"
		action = "按回车重新开始"
		tint = RED
	elif screen_phase == "结算":
		title = "撤离成功"
		subtitle = "你带着战利品离开了监狱"
		action = "按回车开始下一局"
		tint = AMBER
	_draw_label(font, panel.position + Vector2(42.0, 76.0), title, 30, INK)
	_draw_label(font, panel.position + Vector2(44.0, 100.0), "最终版本  /  监狱区段 01", 11, tint)
	_draw_label(font, panel.position + Vector2(82.0, 184.0), subtitle, 15, MUTED)
	_draw_card(Rect2(panel.position + Vector2(232.0, 250.0), Vector2(256.0, 64.0)), tint, 0.94)
	_draw_label(font, panel.position + Vector2(293.0, 289.0), action, 16, BG)
	_draw_label(font, panel.position + Vector2(160.0, 360.0), "目标：修复三处电源 → 唤醒并击败守卫者 → 抵达撤离门", 11, MUTED)

func _draw_section(font: Font, position: Vector2, label: String) -> void:
	_draw_label(font, position, label, 13, MINT)
	draw_line(position + Vector2(0.0, 8.0), position + Vector2(330.0, 8.0), Color("3C5660"), 1.0)

func _draw_card(rect: Rect2, accent: Color, alpha: float) -> void:
	draw_rect(rect, Color(PANEL, alpha), true)
	draw_rect(rect, Color(accent, alpha), false, 2.0)
	draw_line(rect.position + Vector2(0.0, 6.0), rect.position + Vector2(18.0, 6.0), accent, 2.0)
	draw_line(rect.end - Vector2(18.0, 6.0), rect.end - Vector2(0.0, 6.0), accent, 2.0)

func _draw_label(font: Font, position: Vector2, label: String, size: int, color: Color) -> void:
	draw_string(font, position, label, HORIZONTAL_ALIGNMENT_LEFT, -1.0, size, color)

func _draw_bar(rect: Rect2, ratio: float, fill_color: Color) -> void:
	draw_rect(rect, Color("273842"), true)
	draw_rect(Rect2(rect.position, Vector2(rect.size.x * clampf(ratio, 0.0, 1.0), rect.size.y)), fill_color, true)
	draw_rect(rect, Color("8CA7A8"), false, 1.0)

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
		"Safehouse": "安全屋",
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
		"Safehouse resupply": "安全屋补给",
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
