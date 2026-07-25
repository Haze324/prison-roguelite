class_name Merchant
extends Node2D

var player: Player

func setup(target: Player) -> void:
	player = target
	queue_redraw()

func _process(_delta: float) -> void:
	if player == null or global_position.distance_to(player.global_position) > 48.0:
		return
	if Input.is_action_just_pressed("interact"):
		if MetaProgression.coins < 15:
			EventBus.consumable_used.emit("Merchant: need 15 coins")
			return
		MetaProgression.add_coins(-15)
		player.medkits = mini(player.medkits + 1, 5)
		player.current_ammo = player.weapons[player.current_weapon_index].mag_size if not player.weapons.is_empty() else 0
		if not player.weapons.is_empty():
			player.ammo_changed.emit(player.current_ammo, player.weapons[player.current_weapon_index].mag_size)
		EventBus.consumable_used.emit("Merchant: medkit + ammo restocked (-15 coins)")

func _draw() -> void:
	draw_rect(Rect2(-28.0, -26.0, 56.0, 52.0), Color(0.08, 0.12, 0.16, 1.0), true)
	draw_rect(Rect2(-28.0, -26.0, 56.0, 52.0), Color(0.42, 0.75, 0.95, 1.0), false, 2.0)
	draw_circle(Vector2(0.0, -4.0), 10.0, Color(0.42, 0.75, 0.95, 1.0))
	draw_string(ThemeDB.fallback_font, Vector2(-42.0, -38.0), "MERCHANT", HORIZONTAL_ALIGNMENT_LEFT, -1.0, 10, Color(0.65, 0.86, 1.0, 1.0))
	draw_string(ThemeDB.fallback_font, Vector2(-45.0, 44.0), "E: 15 COINS", HORIZONTAL_ALIGNMENT_LEFT, -1.0, 10, Color(0.9, 0.82, 0.55, 1.0))
