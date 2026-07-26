class_name Merchant
extends Node2D

var player: Player

func setup(target: Player) -> void:
	player = target
	queue_redraw()

func _process(_delta: float) -> void:
	queue_redraw()
	if player == null or global_position.distance_to(player.global_position) > 48.0:
		return
	if Input.is_action_just_pressed("interact"):
		var can_supply_medkit: bool = player.medkits < player.get_medkit_maximum()
		var can_supply_ammo: bool = false
		for weapon_index in player.weapons.size():
			var weapon: WeaponData = player.weapons[weapon_index]
			if weapon == null or weapon.mag_size <= 0:
				continue
			var weapon_key: int = weapon.get_instance_id()
			var magazine: int = int(player.magazine_ammo.get(weapon_key, weapon.mag_size))
			var reserve: int = int(player.ammo_reserves.get(weapon_key, weapon.reserve_ammo))
			if magazine < weapon.mag_size or reserve < weapon.reserve_ammo:
				can_supply_ammo = true
				break
		if not can_supply_medkit and not can_supply_ammo:
			EventBus.consumable_used.emit("商人：当前补给已满")
			return
		if MetaProgression.coins < 15:
			EventBus.consumable_used.emit("商人：需要 15 枚硬币")
			return
		MetaProgression.add_coins(-15)
		if can_supply_medkit:
			player.medkits += 1
		if can_supply_ammo:
			player.refill_ammo()
		EventBus.consumable_used.emit("商人：医疗包和弹药已补充（-15 枚硬币）")

func _draw() -> void:
	draw_rect(Rect2(-28.0, -26.0, 56.0, 52.0), Color(0.08, 0.12, 0.16, 1.0), true)
	draw_rect(Rect2(-28.0, -26.0, 56.0, 52.0), Color(0.42, 0.75, 0.95, 1.0), false, 2.0)
	draw_circle(Vector2(0.0, -4.0), 10.0, Color(0.42, 0.75, 0.95, 1.0))
	if player != null and global_position.distance_to(player.global_position) <= 100.0:
		draw_string(ThemeDB.fallback_font, Vector2(-34.0, -38.0), "商人", HORIZONTAL_ALIGNMENT_LEFT, -1.0, 10, Color(0.65, 0.86, 1.0, 1.0))
		draw_string(ThemeDB.fallback_font, Vector2(-45.0, 44.0), "E：补给（15 硬币）", HORIZONTAL_ALIGNMENT_LEFT, -1.0, 10, Color(0.9, 0.82, 0.55, 1.0))
