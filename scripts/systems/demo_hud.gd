class_name DemoHUD
extends Control

var health: float = 100.0
var max_health: float = 100.0
var medkits: int = 0
var weapon_name: String = "NONE"
var ammo: int = 0
var ammo_capacity: int = 0
var ammo_reserve: int = 0
var player_state: String = "IDLE"
var temporary_noise: float = 0.0
var residual_noise: float = 0.0
var kills: int = 0
var boss_text: String = "SLEEPING"
var boss_health: float = 0.0
var boss_max_health: float = 1.0
var event_text: String = "READY"
var power_fixed: int = 0
var power_total: int = 3
var armor_durability: int = 0
var armor_maximum: int = 0
var throwable_summary: String = "-"
var quick_slot_counts: Array[int] = [0, 0, 0, 0]
var selected_quick_slot: int = 0
var coins: int = 0
var skill_points: int = 0
var inventory_open: bool = false
var damage_flash_remaining: float = 0.0
var parry_flash_remaining: float = 0.0
var _player: Player
var screen_phase: String = "MENU"

func _ready() -> void:
    process_mode = Node.PROCESS_MODE_ALWAYS
    mouse_filter = Control.MOUSE_FILTER_IGNORE
	_player = get_node_or_null("../../Player") as Player
	EventBus.damage_feedback.connect(_on_damage_feedback)
	EventBus.player_parried.connect(_on_player_parried)
	queue_redraw()

func _unhandled_input(event: InputEvent) -> void:
    if event.is_action_pressed("inventory") and screen_phase == "RUN":
        inventory_open = not inventory_open
        get_tree().paused = inventory_open
        queue_redraw()
        get_viewport().set_input_as_handled()
    elif event.is_action_pressed("ui_accept") and screen_phase == "MENU":
        EventBus.run_start_requested.emit()
        get_viewport().set_input_as_handled()
    elif event.is_action_pressed("ui_accept") and (screen_phase == "DEATH" or screen_phase == "RESULT"):
        EventBus.run_restart_requested.emit()
        get_viewport().set_input_as_handled()

func show_main_menu() -> void:
    screen_phase = "MENU"
    inventory_open = false
    get_tree().paused = true
    queue_redraw()

func show_run() -> void:
    screen_phase = "RUN"
    inventory_open = false
    get_tree().paused = false
    queue_redraw()

func show_death() -> void:
    screen_phase = "DEATH"
    inventory_open = false
    get_tree().paused = true
    queue_redraw()

func show_result() -> void:
    screen_phase = "RESULT"
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
    weapon_name = current_weapon.to_upper()
    ammo = current_ammo
    ammo_capacity = capacity
    ammo_reserve = reserve
    player_state = state.to_upper()
    temporary_noise = temp_noise
    residual_noise = residual
    kills = defeated
    boss_text = boss_status.to_upper()
    boss_health = current_boss_health
    boss_max_health = maximum_boss_health
    event_text = latest_event
    power_fixed = current_power
    power_total = total_power
    armor_durability = current_armor
    armor_maximum = maximum_armor
    throwable_summary = throwables
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
    var panel_color := Color(0.025, 0.035, 0.045, 0.94)
    var border_color := Color(0.28, 0.78, 0.68, 0.95)
    var accent := Color(0.36, 0.92, 0.74, 1.0)
    var warning := Color(1.0, 0.72, 0.28, 1.0)
    var danger := Color(1.0, 0.32, 0.34, 1.0)
    var noise_total: float = temporary_noise + residual_noise

    var status_rect := Rect2(16.0, 16.0, 330.0, 194.0)
    draw_rect(status_rect, panel_color, true)
    draw_rect(status_rect, border_color, false, 2.0)
    draw_string(font, Vector2(30.0, 40.0), "PRISON // RUN 01", HORIZONTAL_ALIGNMENT_LEFT, -1.0, 16, Color.WHITE)
    draw_string(font, Vector2(30.0, 58.0), "SURVIVOR STATUS", HORIZONTAL_ALIGNMENT_LEFT, -1.0, 10, Color(0.58, 0.72, 0.76, 1.0))
    draw_string(font, Vector2(30.0, 82.0), "HP", HORIZONTAL_ALIGNMENT_LEFT, -1.0, 12, Color.WHITE)
    _draw_bar(Rect2(66.0, 72.0, 150.0, 11.0), health / maxf(max_health, 1.0), danger)
    draw_string(font, Vector2(234.0, 82.0), "MED x%d" % medkits, HORIZONTAL_ALIGNMENT_LEFT, -1.0, 12, Color(0.9, 0.82, 0.62, 1.0))
    draw_string(font, Vector2(30.0, 106.0), "AMMO", HORIZONTAL_ALIGNMENT_LEFT, -1.0, 12, Color.WHITE)
    draw_string(font, Vector2(82.0, 106.0), "%s  %d/%d +%d" % [weapon_name, ammo, ammo_capacity, ammo_reserve], HORIZONTAL_ALIGNMENT_LEFT, -1.0, 11, accent)
    draw_string(font, Vector2(30.0, 130.0), "ARMOR", HORIZONTAL_ALIGNMENT_LEFT, -1.0, 12, Color.WHITE)
    draw_string(font, Vector2(82.0, 130.0), "%d/%d" % [armor_durability, armor_maximum], HORIZONTAL_ALIGNMENT_LEFT, -1.0, 12, Color(0.6, 0.82, 0.96, 1.0))
    draw_string(font, Vector2(160.0, 130.0), "POWER %d/%d" % [power_fixed, power_total], HORIZONTAL_ALIGNMENT_LEFT, -1.0, 12, warning)
    draw_string(font, Vector2(30.0, 154.0), "THROW", HORIZONTAL_ALIGNMENT_LEFT, -1.0, 12, Color.WHITE)
    draw_string(font, Vector2(82.0, 154.0), throwable_summary, HORIZONTAL_ALIGNMENT_LEFT, -1.0, 12, Color(0.82, 0.7, 0.95, 1.0))
    draw_string(font, Vector2(30.0, 178.0), "KILLS %02d   COINS %d   SKILL %d   %s" % [kills, coins, skill_points, player_state], HORIZONTAL_ALIGNMENT_LEFT, -1.0, 11, Color(0.72, 0.84, 0.88, 1.0))

    var mission_rect := Rect2(screen.x - 250.0, 16.0, 234.0, 166.0)
    draw_rect(mission_rect, panel_color, true)
    draw_rect(mission_rect, Color(0.75, 0.42, 0.25, 0.95), false, 2.0)
    draw_string(font, mission_rect.position + Vector2(14.0, 26.0), "THREAT MONITOR", HORIZONTAL_ALIGNMENT_LEFT, -1.0, 15, Color.WHITE)
    draw_string(font, mission_rect.position + Vector2(14.0, 50.0), "NOISE", HORIZONTAL_ALIGNMENT_LEFT, -1.0, 12, Color(0.78, 0.86, 0.88, 1.0))
    var noise_color: Color = accent if noise_total <= 50.0 else warning if noise_total <= 120.0 else danger
    _draw_bar(Rect2(mission_rect.position + Vector2(14.0, 58.0), Vector2(206.0, 12.0)), noise_total / 200.0, noise_color)
    draw_string(font, mission_rect.position + Vector2(14.0, 88.0), "%.0f TEMP  +  %.0f RESIDUAL" % [temporary_noise, residual_noise], HORIZONTAL_ALIGNMENT_LEFT, -1.0, 10, Color(0.95, 0.78, 0.5, 1.0))
    draw_string(font, mission_rect.position + Vector2(14.0, 116.0), "BOSS", HORIZONTAL_ALIGNMENT_LEFT, -1.0, 12, Color(0.78, 0.86, 0.88, 1.0))
    draw_string(font, mission_rect.position + Vector2(62.0, 116.0), boss_text, HORIZONTAL_ALIGNMENT_LEFT, -1.0, 12, danger if boss_text != "SLEEPING" else accent)
    draw_string(font, mission_rect.position + Vector2(14.0, 145.0), "NOISE 200 = WARDEN AWAKENS", HORIZONTAL_ALIGNMENT_LEFT, -1.0, 10, Color(0.66, 0.72, 0.76, 1.0))

    var event_rect := Rect2(16.0, screen.y - 66.0, screen.x - 32.0, 30.0)
    draw_rect(event_rect, Color(0.025, 0.035, 0.045, 0.9), true)
    draw_rect(event_rect, Color(0.34, 0.48, 0.52, 0.9), false, 1.0)
    draw_string(font, event_rect.position + Vector2(12.0, 20.0), "> " + event_text, HORIZONTAL_ALIGNMENT_LEFT, event_rect.size.x - 24.0, 13, Color(0.88, 0.9, 0.82, 1.0))

    var controls := "WASD MOVE   SHIFT RUN   SPACE DASH   T LIGHT   LMB FIRE   1/2 WEAPON   R RELOAD   RMB AIM/PARRY   Q HEAL   E INTERACT"
    draw_string(font, Vector2(18.0, screen.y - 12.0), controls, HORIZONTAL_ALIGNMENT_LEFT, screen.x - 36.0, 11, Color(0.65, 0.72, 0.74, 1.0))
    _draw_quickbar(font, screen)
    if noise_total >= 121.0:
        var edge_alpha: float = clampf((noise_total - 120.0) / 80.0, 0.12, 0.4)
        draw_rect(Rect2(0.0, 0.0, screen.x, 12.0), Color(1.0, 0.12, 0.14, edge_alpha), true)
        draw_rect(Rect2(0.0, screen.y - 12.0, screen.x, 12.0), Color(1.0, 0.12, 0.14, edge_alpha), true)
        draw_rect(Rect2(0.0, 0.0, 12.0, screen.y), Color(1.0, 0.12, 0.14, edge_alpha), true)
        draw_rect(Rect2(screen.x - 12.0, 0.0, 12.0, screen.y), Color(1.0, 0.12, 0.14, edge_alpha), true)
	if boss_health > 0.0:
		_draw_boss_bar(font, screen, danger)
	if damage_flash_remaining > 0.0:
		var damage_alpha: float = damage_flash_remaining / 0.22 * 0.24
		draw_rect(Rect2(Vector2.ZERO, screen), Color(1.0, 0.08, 0.12, damage_alpha), true)
	if parry_flash_remaining > 0.0:
		var parry_alpha: float = parry_flash_remaining / 0.28 * 0.28
		draw_rect(Rect2(Vector2.ZERO, screen), Color(0.4, 0.9, 1.0, parry_alpha), true)

    var cursor: Vector2 = get_viewport().get_mouse_position()
    draw_line(cursor + Vector2(-10.0, 0.0), cursor + Vector2(-3.0, 0.0), accent, 2.0)
    draw_line(cursor + Vector2(3.0, 0.0), cursor + Vector2(10.0, 0.0), accent, 2.0)
    draw_line(cursor + Vector2(0.0, -10.0), cursor + Vector2(0.0, -3.0), accent, 2.0)
    draw_line(cursor + Vector2(0.0, 3.0), cursor + Vector2(0.0, 10.0), accent, 2.0)
    draw_circle(cursor, 2.0, accent)

    if inventory_open:
        _draw_inventory(font, accent, warning)
    elif screen_phase != "RUN":
        _draw_screen_overlay(font, accent, warning)

func _draw_screen_overlay(font: Font, accent: Color, warning: Color) -> void:
    var screen: Vector2 = get_viewport_rect().size
    draw_rect(Rect2(Vector2.ZERO, screen), Color(0.015, 0.02, 0.025, 0.78), true)
    var panel := Rect2((screen - Vector2(760.0, 520.0)) * 0.5, Vector2(760.0, 520.0))
    draw_texture_rect(PaperUITheme.BOOK_DESK, panel, false, Color(1.0, 1.0, 1.0, 0.98))
    draw_texture_rect(PaperUITheme.BANNER_CUTOUT, Rect2(panel.position + Vector2(92.0, 42.0), Vector2(576.0, 176.0) * 0.62), false)
    var title := "PRISON // RUN 01"
    var subtitle := "PRESS ENTER TO BEGIN"
    var body := "Restore power. Stay quiet. Find the Warden."
    var tint := accent
    if screen_phase == "DEATH":
        title = "RUN LOST"
        subtitle = "PRESS ENTER TO RETURN"
        body = "Your carried gear is gone. Meta progression remains."
        tint = Color(0.95, 0.32, 0.36, 1.0)
    elif screen_phase == "RESULT":
        title = "EXTRACTION COMPLETE"
        subtitle = "PRESS ENTER FOR NEXT RUN"
        body = "Coins and skill points have been added to your safehouse."
        tint = warning
    draw_string(font, panel.position + Vector2(205.0, 118.0), title, HORIZONTAL_ALIGNMENT_LEFT, -1.0, 24, Color(0.18, 0.25, 0.25, 1.0))
    draw_string(font, panel.position + Vector2(220.0, 160.0), subtitle, HORIZONTAL_ALIGNMENT_LEFT, -1.0, 13, tint)
    draw_string(font, panel.position + Vector2(155.0, 282.0), body, HORIZONTAL_ALIGNMENT_LEFT, -1.0, 14, Color(0.25, 0.3, 0.3, 1.0))
    draw_texture_rect(PaperUITheme.BUTTON_NORMAL, Rect2(panel.position + Vector2(280.0, 340.0), Vector2(200.0, 80.0)), false, Color(1.0, 1.0, 1.0, 0.96))
    draw_string(font, panel.position + Vector2(326.0, 387.0), "ENTER", HORIZONTAL_ALIGNMENT_LEFT, -1.0, 18, Color(0.18, 0.25, 0.25, 1.0))

func _draw_inventory(font: Font, accent: Color, warning: Color) -> void:
    var screen: Vector2 = get_viewport_rect().size
    draw_rect(Rect2(Vector2.ZERO, screen), Color(0.015, 0.02, 0.025, 0.72), true)
    var panel := Rect2((screen - Vector2(760.0, 520.0)) * 0.5, Vector2(760.0, 520.0))
    draw_texture_rect(PaperUITheme.BOOK_DESK, panel, false, Color(1.0, 1.0, 1.0, 0.98))
    draw_texture_rect(PaperUITheme.BANNER_PLAIN, Rect2(panel.position + Vector2(92.0, 20.0), Vector2(576.0, 176.0) * 0.62), false)
    draw_string(font, panel.position + Vector2(220.0, 72.0), "FIELD INVENTORY", HORIZONTAL_ALIGNMENT_LEFT, -1.0, 22, Color(0.18, 0.25, 0.25, 1.0))
    draw_string(font, panel.position + Vector2(245.0, 98.0), "TAB  CLOSE", HORIZONTAL_ALIGNMENT_LEFT, -1.0, 11, Color(0.3, 0.42, 0.4, 1.0))

    var left := panel.position + Vector2(62.0, 150.0)
    draw_string(font, left, "EQUIPMENT", HORIZONTAL_ALIGNMENT_LEFT, -1.0, 14, Color(0.18, 0.25, 0.25, 1.0))
    _draw_inventory_slot(font, left + Vector2(0.0, 20.0), "SLOT 1", _weapon_label(0), accent)
    _draw_inventory_slot(font, left + Vector2(0.0, 112.0), "SLOT 2", _weapon_label(1), warning)

    var right := panel.position + Vector2(400.0, 150.0)
    draw_string(font, right, "SUPPLIES", HORIZONTAL_ALIGNMENT_LEFT, -1.0, 14, Color(0.18, 0.25, 0.25, 1.0))
    _draw_inventory_slot(font, right + Vector2(0.0, 20.0), "MEDKIT", "x%d" % medkits, Color(0.85, 0.3, 0.35, 1.0))
    _draw_inventory_slot(font, right + Vector2(0.0, 112.0), "THROWABLES", throwable_summary, Color(0.5, 0.35, 0.75, 1.0))
    _draw_inventory_quickbar(font, panel.position + Vector2(390.0, 360.0))
    draw_string(font, panel.position + Vector2(64.0, 462.0), "COINS  %d     SKILL POINTS  %d" % [coins, skill_points], HORIZONTAL_ALIGNMENT_LEFT, -1.0, 13, Color(0.28, 0.4, 0.38, 1.0))

func _draw_boss_bar(font: Font, screen: Vector2, danger: Color) -> void:
    var bar := Rect2(screen.x * 0.5 - 240.0, 198.0, 480.0, 18.0)
    draw_string(font, bar.position + Vector2(0.0, -8.0), "WARDEN  " + boss_text, HORIZONTAL_ALIGNMENT_LEFT, -1.0, 12, danger)
    _draw_bar(bar, boss_health / maxf(boss_max_health, 1.0), danger)

func _draw_quickbar(font: Font, screen: Vector2) -> void:
    var slot_size := 58.0
    var gap := 8.0
    var total_width := slot_size * 4.0 + gap * 3.0
    var start_x := (screen.x - total_width) * 0.5
    var y := screen.y - 142.0
    for index in 4:
        _draw_quick_slot(font, Vector2(start_x + index * (slot_size + gap), y), slot_size, index)

func _draw_inventory_quickbar(font: Font, position: Vector2) -> void:
    draw_string(font, position, "QUICK SLOTS  3  4  5  6", HORIZONTAL_ALIGNMENT_LEFT, -1.0, 12, Color(0.22, 0.3, 0.3, 1.0))
    for index in 4:
        _draw_quick_slot(font, position + Vector2(index * 62.0, 18.0), 52.0, index)

func _draw_quick_slot(font: Font, position: Vector2, slot_size: float, index: int) -> void:
    var tint := _quick_color(index)
    var alpha := 1.0 if index == selected_quick_slot else 0.76
    draw_texture_rect(PaperUITheme.SLOT_HOLDER, Rect2(position, Vector2(slot_size, slot_size)), false, Color(1.0, 1.0, 1.0, alpha))
    draw_texture_rect(PaperUITheme.ITEM_ICON, Rect2(position + Vector2(slot_size * 0.5 - 8.0, slot_size * 0.5 - 8.0), Vector2(16.0, 16.0)), false, tint)
    if index == selected_quick_slot:
        draw_arc(position + Vector2(slot_size * 0.5, slot_size * 0.5), slot_size * 0.47, 0.0, TAU, 32, tint, 2.0)
    draw_string(font, position + Vector2(5.0, 14.0), str(index + 3), HORIZONTAL_ALIGNMENT_LEFT, -1.0, 11, Color(0.18, 0.25, 0.25, 1.0))
    var count: int = quick_slot_counts[index] if index < quick_slot_counts.size() else 0
    draw_string(font, position + Vector2(slot_size - 18.0, slot_size - 7.0), str(count), HORIZONTAL_ALIGNMENT_LEFT, -1.0, 11, tint if count > 0 else Color(0.45, 0.45, 0.45, 1.0))

func _quick_color(index: int) -> Color:
    match index:
        0:
            return Color(1.0, 0.78, 0.28, 1.0)
        1:
            return Color(0.65, 0.7, 0.78, 1.0)
        2:
            return Color(0.95, 0.3, 0.2, 1.0)
        _:
            return Color(0.75, 0.25, 0.85, 1.0)

func _draw_inventory_slot(font: Font, position: Vector2, slot_name: String, value: String, tint: Color) -> void:
    draw_texture_rect(PaperUITheme.SLOT_HOLDER, Rect2(position, Vector2(72.0, 72.0)), false, Color(1.0, 1.0, 1.0, 0.92))
    draw_texture_rect(PaperUITheme.ITEM_ICON, Rect2(position + Vector2(28.0, 28.0), Vector2(16.0, 16.0)), false, tint)
    draw_string(ThemeDB.fallback_font, position + Vector2(84.0, 27.0), slot_name, HORIZONTAL_ALIGNMENT_LEFT, -1.0, 12, Color(0.22, 0.3, 0.3, 1.0))
    draw_string(ThemeDB.fallback_font, position + Vector2(84.0, 49.0), value, HORIZONTAL_ALIGNMENT_LEFT, -1.0, 13, tint)

func _weapon_label(index: int) -> String:
    if _player == null or index >= _player.weapons.size():
        return "EMPTY"
    var weapon: WeaponData = _player.weapons[index]
    return "%s  %d/%d" % [weapon.weapon_name, _player.current_ammo if index == _player.current_weapon_index else weapon.mag_size, weapon.mag_size]

func _draw_bar(rect: Rect2, ratio: float, fill_color: Color) -> void:
    draw_rect(rect, Color(0.08, 0.1, 0.12, 1.0), true)
    draw_rect(Rect2(rect.position, Vector2(rect.size.x * clampf(ratio, 0.0, 1.0), rect.size.y)), fill_color, true)
	draw_rect(rect, Color(0.65, 0.74, 0.75, 0.8), false, 1.0)

func _on_damage_feedback(_target: Node2D, _amount: float, _position: Vector2, is_player: bool) -> void:
	if is_player:
		damage_flash_remaining = 0.22

func _on_player_parried(_attacker: Node2D) -> void:
	parry_flash_remaining = 0.28
