class_name DemoHUD
extends Control

var health: float = 100.0
var max_health: float = 100.0
var medkits: int = 0
var weapon_name: String = "NONE"
var ammo: int = 0
var ammo_capacity: int = 0
var player_state: String = "IDLE"
var temporary_noise: float = 0.0
var residual_noise: float = 0.0
var kills: int = 0
var boss_text: String = "SLEEPING"
var event_text: String = "READY"
var power_fixed: int = 0
var power_total: int = 3
var armor_durability: int = 0
var armor_maximum: int = 0
var throwable_summary: String = "-"
var coins: int = 0
var skill_points: int = 0

func _ready() -> void:
    mouse_filter = Control.MOUSE_FILTER_IGNORE
    queue_redraw()

func set_data(
    current_health: float,
    maximum_health: float,
    current_medkits: int,
    current_weapon: String,
    current_ammo: int,
    capacity: int,
    state: String,
    temp_noise: float,
    residual: float,
    defeated: int,
    boss_status: String,
    latest_event: String,
    current_power: int,
    total_power: int,
    current_armor: int,
    maximum_armor: int,
    throwables: String,
    meta_coins: int,
    meta_skill_points: int
) -> void:
    health = current_health
    max_health = maximum_health
    medkits = current_medkits
    weapon_name = current_weapon.to_upper()
    ammo = current_ammo
    ammo_capacity = capacity
    player_state = state.to_upper()
    temporary_noise = temp_noise
    residual_noise = residual
    kills = defeated
    boss_text = boss_status.to_upper()
    event_text = latest_event
    power_fixed = current_power
    power_total = total_power
    armor_durability = current_armor
    armor_maximum = maximum_armor
    throwable_summary = throwables
    coins = meta_coins
    skill_points = meta_skill_points
    queue_redraw()

func _process(_delta: float) -> void:
    queue_redraw()

func _draw() -> void:
    var screen: Vector2 = get_viewport_rect().size
    var font: Font = ThemeDB.fallback_font
    var panel_color := Color(0.025, 0.035, 0.045, 0.94)
    var border_color := Color(0.28, 0.78, 0.68, 0.95)
    var accent := Color(0.36, 0.92, 0.74, 1.0)
    var warning := Color(1.0, 0.72, 0.28, 1.0)
    var danger := Color(1.0, 0.32, 0.34, 1.0)

    var status_rect := Rect2(16.0, 16.0, 330.0, 246.0)
    draw_rect(status_rect, panel_color, true)
    draw_rect(status_rect, border_color, false, 2.0)
    draw_string(font, Vector2(30.0, 42.0), "PRISON // RUN 01", HORIZONTAL_ALIGNMENT_LEFT, -1.0, 18, Color.WHITE)
    draw_string(font, Vector2(30.0, 64.0), "SURVIVOR STATUS", HORIZONTAL_ALIGNMENT_LEFT, -1.0, 11, Color(0.58, 0.72, 0.76, 1.0))
    draw_string(font, Vector2(30.0, 88.0), "HP", HORIZONTAL_ALIGNMENT_LEFT, -1.0, 13, Color.WHITE)
    _draw_bar(Rect2(66.0, 77.0, 210.0, 13.0), health / maxf(max_health, 1.0), danger)
    draw_string(font, Vector2(30.0, 112.0), "AMMO", HORIZONTAL_ALIGNMENT_LEFT, -1.0, 13, Color.WHITE)
    draw_string(font, Vector2(82.0, 112.0), "%s   %d / %d" % [weapon_name, ammo, ammo_capacity], HORIZONTAL_ALIGNMENT_LEFT, -1.0, 13, accent)
    draw_string(font, Vector2(30.0, 136.0), "MEDKITS", HORIZONTAL_ALIGNMENT_LEFT, -1.0, 13, Color.WHITE)
    draw_string(font, Vector2(104.0, 136.0), "x%d    STATE: %s" % [medkits, player_state], HORIZONTAL_ALIGNMENT_LEFT, -1.0, 13, Color(0.9, 0.82, 0.62, 1.0))
    draw_string(font, Vector2(30.0, 160.0), "ARMOR", HORIZONTAL_ALIGNMENT_LEFT, -1.0, 13, Color.WHITE)
    draw_string(font, Vector2(100.0, 160.0), "%d / %d" % [armor_durability, armor_maximum], HORIZONTAL_ALIGNMENT_LEFT, -1.0, 13, Color(0.6, 0.82, 0.96, 1.0))
    draw_string(font, Vector2(30.0, 184.0), "POWER", HORIZONTAL_ALIGNMENT_LEFT, -1.0, 13, Color.WHITE)
    draw_string(font, Vector2(100.0, 184.0), "%d / %d" % [power_fixed, power_total], HORIZONTAL_ALIGNMENT_LEFT, -1.0, 13, warning)
    draw_string(font, Vector2(30.0, 208.0), "THROWABLES", HORIZONTAL_ALIGNMENT_LEFT, -1.0, 13, Color.WHITE)
    draw_string(font, Vector2(128.0, 208.0), throwable_summary, HORIZONTAL_ALIGNMENT_LEFT, -1.0, 13, Color(0.82, 0.7, 0.95, 1.0))
    draw_string(font, Vector2(30.0, 232.0), "KILLS %02d   COINS %d   SKILL %d" % [kills, coins, skill_points], HORIZONTAL_ALIGNMENT_LEFT, -1.0, 12, Color(0.72, 0.84, 0.88, 1.0))

    var mission_rect := Rect2(screen.x - 250.0, 16.0, 234.0, 166.0)
    draw_rect(mission_rect, panel_color, true)
    draw_rect(mission_rect, Color(0.75, 0.42, 0.25, 0.95), false, 2.0)
    draw_string(font, mission_rect.position + Vector2(14.0, 26.0), "THREAT MONITOR", HORIZONTAL_ALIGNMENT_LEFT, -1.0, 15, Color.WHITE)
    draw_string(font, mission_rect.position + Vector2(14.0, 50.0), "NOISE", HORIZONTAL_ALIGNMENT_LEFT, -1.0, 12, Color(0.78, 0.86, 0.88, 1.0))
    _draw_bar(Rect2(mission_rect.position + Vector2(14.0, 58.0), Vector2(206.0, 12.0)), (temporary_noise + residual_noise) / 200.0, warning)
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

    var cursor: Vector2 = get_viewport().get_mouse_position()
    draw_line(cursor + Vector2(-10.0, 0.0), cursor + Vector2(-3.0, 0.0), accent, 2.0)
    draw_line(cursor + Vector2(3.0, 0.0), cursor + Vector2(10.0, 0.0), accent, 2.0)
    draw_line(cursor + Vector2(0.0, -10.0), cursor + Vector2(0.0, -3.0), accent, 2.0)
    draw_line(cursor + Vector2(0.0, 3.0), cursor + Vector2(0.0, 10.0), accent, 2.0)
    draw_circle(cursor, 2.0, accent)

func _draw_bar(rect: Rect2, ratio: float, fill_color: Color) -> void:
    draw_rect(rect, Color(0.08, 0.1, 0.12, 1.0), true)
    draw_rect(Rect2(rect.position, Vector2(rect.size.x * clampf(ratio, 0.0, 1.0), rect.size.y)), fill_color, true)
    draw_rect(rect, Color(0.65, 0.74, 0.75, 0.8), false, 1.0)
