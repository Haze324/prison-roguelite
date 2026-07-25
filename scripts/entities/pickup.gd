class_name Pickup
extends Node2D

var item_name: String = "Ammo"
var amount: int = 1
var tint: Color = Color(0.35, 0.75, 0.85, 1.0)
var pulse_time: float = 0.0
var player: Player
var item_data: ConsumableData
var weapon_data: WeaponData

func setup(pickup_name: String, pickup_amount: int, pickup_tint: Color, target_player: Player = null) -> void:
    item_name = pickup_name
    amount = pickup_amount
    tint = pickup_tint
    player = target_player
    item_data = null
    weapon_data = null
    add_to_group("pickups")
    queue_redraw()

func setup_data(data: ConsumableData, pickup_amount: int, pickup_tint: Color, target_player: Player = null) -> void:
    item_data = data
    item_name = data.item_name if data != null else "Unknown"
    amount = pickup_amount
    tint = pickup_tint
    player = target_player
    weapon_data = null
    add_to_group("pickups")
    queue_redraw()

func setup_weapon(data: WeaponData, pickup_tint: Color, target_player: Player = null) -> void:
    weapon_data = data
    item_data = null
    item_name = data.weapon_name if data != null else "Unknown Weapon"
    amount = 1
    tint = pickup_tint
    player = target_player
    add_to_group("pickups")
    queue_redraw()

func _process(delta: float) -> void:
    pulse_time += delta
    queue_redraw()

func collect(target_player: Player) -> void:
    if weapon_data != null:
        if target_player.weapons.size() >= 2:
            target_player.weapons[1] = weapon_data
            target_player.register_weapon(weapon_data)
            target_player.equip_weapon(1)
    elif item_data != null:
        if item_data.item_type == GameEnums.ConsumableType.HEALING:
            target_player.medkits = mini(target_player.medkits + amount, item_data.max_carry)
        elif item_data.item_type == GameEnums.ConsumableType.THROWABLE:
            target_player.add_throwable(item_data.throwable_type, amount, item_data.max_carry)
        elif item_data.item_type == GameEnums.ConsumableType.AMMO:
            target_player.refill_ammo()
    elif item_name == "Medkit":
        target_player.medkits = mini(target_player.medkits + amount, 5)
    elif item_name == "Ammo":
        target_player.refill_ammo()
    elif item_name == "Shotgun":
        var shotgun: WeaponData = load("res://resources/weapons/shotgun_common.tres") as WeaponData
        if shotgun != null and target_player.weapons.size() >= 2:
            target_player.weapons[1] = shotgun
            target_player.register_weapon(shotgun)
            target_player.equip_weapon(1)
    EventBus.consumable_used.emit("拾取：" + _display_name(item_name) + " ×%d" % amount)
    queue_free()

func _draw() -> void:
    var bob: float = sin(pulse_time * 3.0) * 2.0
    draw_circle(Vector2(0.0, bob), 13.0, Color(0.02, 0.02, 0.03, 0.75))
    draw_circle(Vector2(0.0, bob), 9.0, tint)
    draw_line(Vector2(-5.0, bob), Vector2(5.0, bob), Color.WHITE, 2.0)
    draw_line(Vector2(0.0, bob - 5.0), Vector2(0.0, bob + 5.0), Color.WHITE, 2.0)
    var nearby: bool = player == null or global_position.distance_to(player.global_position) <= 120.0
    if nearby:
        draw_string(ThemeDB.fallback_font, Vector2(-42.0, -18.0 + bob), _display_name(item_name), HORIZONTAL_ALIGNMENT_LEFT, -1.0, 10, tint)

func _display_name(value: String) -> String:
    return value.replace("Medkit", "医疗包").replace("Ammo", "弹药").replace("Shotgun", "霰弹枪").replace("Pistol", "手枪").replace("Crowbar", "撬棍").replace("Flare", "信号弹").replace("Smoke", "烟雾弹").replace("Grenade", "手雷").replace("Mine", "地雷").replace("Fine", "精良").replace("Common", "普通").replace("Rare", "稀有").replace("Epic", "史诗").replace("Legendary", "传说").replace("Unknown Weapon", "未知武器").replace("Unknown", "未知物品")
