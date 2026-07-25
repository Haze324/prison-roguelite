class_name Pickup
extends Node2D

var item_name: String = "Ammo"
var amount: int = 1
var tint: Color = Color(0.35, 0.75, 0.85, 1.0)
var pulse_time: float = 0.0

func setup(pickup_name: String, pickup_amount: int, pickup_tint: Color) -> void:
    item_name = pickup_name
    amount = pickup_amount
    tint = pickup_tint
    add_to_group("pickups")
    queue_redraw()

func _process(delta: float) -> void:
    pulse_time += delta
    queue_redraw()

func collect(player: Player) -> void:
    if item_name == "Medkit":
        player.medkits = mini(player.medkits + amount, 5)
    elif item_name == "Ammo":
        if not player.weapons.is_empty():
            player.current_ammo = player.weapons[player.current_weapon_index].mag_size
            player.ammo_changed.emit(player.current_ammo, player.weapons[player.current_weapon_index].mag_size)
    elif item_name == "Shotgun":
        var shotgun: WeaponData = load("res://resources/weapons/shotgun_common.tres") as WeaponData
        if shotgun != null and player.weapons.size() >= 2:
            player.weapons[1] = shotgun
            player.equip_weapon(1)
    EventBus.consumable_used.emit(item_name + " +%d" % amount)
    queue_free()

func _draw() -> void:
    var bob: float = sin(pulse_time * 3.0) * 2.0
    draw_circle(Vector2(0.0, bob), 13.0, Color(0.02, 0.02, 0.03, 0.75))
    draw_circle(Vector2(0.0, bob), 9.0, tint)
    draw_line(Vector2(-5.0, bob), Vector2(5.0, bob), Color.WHITE, 2.0)
    draw_line(Vector2(0.0, bob - 5.0), Vector2(0.0, bob + 5.0), Color.WHITE, 2.0)
    draw_string(ThemeDB.fallback_font, Vector2(-32.0, -18.0 + bob), item_name.to_upper(), HORIZONTAL_ALIGNMENT_LEFT, -1.0, 10, tint)
