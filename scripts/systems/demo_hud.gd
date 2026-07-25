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
var coins: int = 0
var skill_points: int = 0
var inventory_open: bool = false
var damage_flash_remaining: float = 0.0
var parry_flash_remaining: float = 0.0
var _player: Player
var screen_phase: String = "菜单"

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	_player = get_node_or_null("../../Player") as Player
	EventBus.damage_feedback.connect(_on_damage_feedback)
	EventBus.player_parried.connect(_on_player_parried)
	queue_redraw()

func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("inventory") and screen_phase == "战斗":
		inventory_open = not inventory_open
		get_tree().paused = inventory_open
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
	meta_skill_points: int
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
	coins = meta_coins
	skill_points = meta_skill_points
	queue_redraw()

func _process(delta: float) -> void:
	damage_flash_remaining = maxf(damage_flash_remaining - delta, 0.0)
	parry_flash_remaining = maxf(parry_flash_remaining - delta, 0.0)
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
	_draw_label(font, status_rect.position + Vector2(16.0, 149.0), "医疗包", 11, MUTED)
	_draw_label(font, status_rect.position + Vector2(64.0, 149.0), "×%d" % medkits, 12, RED)
	_draw_label(font, status_rect.position + Vector2(150.0, 149.0), "击杀 %02d" % kills, 11, INK)
	_draw_label(font, status_rect.position + Vector2(250.0, 149.0), player_state, 11, MINT)
	_draw_label(font, status_rect.position + Vector2(16.0, 176.0), "电源 %d / %d" % [power_fixed, power_total], 11, AMBER)
	_draw_label(font, status_rect.position + Vector2(150.0, 176.0), "硬币 %d" % coins, 11, INK)
	_draw_label(font, status_rect.position + Vector2(254.0, 176.0), "技能点 %d" % skill_points, 11, PURPLE)

	var threat_rect: Rect2 = Rect2(screen.x - 278.0, 18.0, 260.0, 184.0)
	_draw_card(threat_rect, RED, 0.94)
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
	_draw_label(font, Vector2(20.0, screen.y - 24.0), "WASD 移动   Shift 奔跑   空格 冲刺   鼠标左键 射击   R 换弹   鼠标右键 瞄准/格挡   Q 治疗   E 互动   Tab 背包", 11, MUTED)
	_draw_quickbar(font, screen)
	if noise_total >= 121.0:
		var edge_alpha: float = clampf((noise_total - 120.0) / 80.0, 0.12, 0.4)
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
	var slot_size: float = 58.0
	var gap: float = 8.0
	var total_width: float = slot_size * 4.0 + gap * 3.0
	var start_x: float = (screen.x - total_width) * 0.5
	var y: float = screen.y - 156.0
	for index in 4:
		_draw_quick_slot(font, Vector2(start_x + index * (slot_size + gap), y), slot_size, index)

func _draw_quick_slot(font: Font, position: Vector2, slot_size: float, index: int) -> void:
	var tint: Color = [AMBER, BLUE, RED, PURPLE][index]
	var outline: Color = tint if index == selected_quick_slot else Color("53636B")
	_draw_card(Rect2(position, Vector2(slot_size, slot_size)), outline, 0.96)
	draw_circle(position + Vector2(slot_size * 0.5, slot_size * 0.5), 13.0, Color(tint, 0.18))
	draw_circle(position + Vector2(slot_size * 0.5, slot_size * 0.5), 7.0, tint)
	_draw_label(font, position + Vector2(7.0, 15.0), str(index + 3), 11, INK)
	var count: int = quick_slot_counts[index] if index < quick_slot_counts.size() else 0
	_draw_label(font, position + Vector2(slot_size - 20.0, slot_size - 8.0), str(count), 11, tint if count > 0 else MUTED)

func _draw_inventory(font: Font, screen: Vector2) -> void:
	draw_rect(Rect2(Vector2.ZERO, screen), Color(0.02, 0.04, 0.05, 0.78), true)
	var panel: Rect2 = Rect2((screen - Vector2(820.0, 560.0)) * 0.5, Vector2(820.0, 560.0))
	_draw_card(panel, MINT, 1.0)
	_draw_label(font, panel.position + Vector2(32.0, 42.0), "现场背包", 26, INK)
	_draw_label(font, panel.position + Vector2(33.0, 66.0), "暂停中  /  Tab 关闭", 11, MUTED)
	_draw_section(font, panel.position + Vector2(34.0, 104.0), "武器装备")
	_draw_inventory_slot(font, panel.position + Vector2(34.0, 122.0), "武器一", _weapon_label(0), AMBER)
	_draw_inventory_slot(font, panel.position + Vector2(34.0, 204.0), "武器二", _weapon_label(1), BLUE)
	_draw_section(font, panel.position + Vector2(438.0, 104.0), "补给品")
	_draw_inventory_slot(font, panel.position + Vector2(438.0, 122.0), "医疗包", "×%d" % medkits, RED)
	_draw_inventory_slot(font, panel.position + Vector2(438.0, 204.0), "投掷物", throwable_summary, PURPLE)
	_draw_section(font, panel.position + Vector2(438.0, 316.0), "快捷栏  /  3  4  5  6")
	for index in 4:
		_draw_quick_slot(font, panel.position + Vector2(438.0 + index * 70.0, 334.0), 58.0, index)
	_draw_label(font, panel.position + Vector2(36.0, 500.0), "硬币 %d     技能点 %d" % [coins, skill_points], 13, AMBER)

func _draw_inventory_slot(font: Font, position: Vector2, slot_name: String, value: String, tint: Color) -> void:
	_draw_card(Rect2(position, Vector2(340.0, 66.0)), Color("53636B"), 0.76)
	draw_circle(position + Vector2(28.0, 33.0), 12.0, Color(tint, 0.22))
	draw_circle(position + Vector2(28.0, 33.0), 6.0, tint)
	_draw_label(font, position + Vector2(54.0, 27.0), slot_name, 11, MUTED)
	_draw_label(font, position + Vector2(54.0, 47.0), value, 12, tint)

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
