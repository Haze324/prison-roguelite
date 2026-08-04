class_name Pickup
extends Node2D

const DRAW_INTERVAL: float = 0.08

var item_name: String = "Ammo"
var amount: int = 1
var tint: Color = Color(0.35, 0.75, 0.85, 1.0)
var pulse_time: float = 0.0
var player: Player
var item_data: ConsumableData
var weapon_data: WeaponData
var _draw_accumulator: float = 0.0
var _player_nearby: bool = false

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
	_draw_accumulator += delta
	pulse_time += delta
	var nearby: bool = player == null or not is_instance_valid(player) or global_position.distance_to(player.global_position) <= 120.0
	if nearby != _player_nearby:
		_player_nearby = nearby
		queue_redraw()
	if _draw_accumulator >= DRAW_INTERVAL:
		_draw_accumulator = 0.0
		queue_redraw()

func collect(target_player: Player) -> bool:
	if target_player == null or not is_instance_valid(target_player):
		return false
	var collected: bool = false
	if weapon_data != null:
		collected = target_player.add_weapon_to_inventory(weapon_data)
	elif item_data != null:
		if item_data.item_type == GameEnums.ConsumableType.HEALING:
			collected = target_player.add_medkits_to_backpack(amount, item_data.max_carry)
		elif item_data.item_type == GameEnums.ConsumableType.THROWABLE:
			collected = target_player.add_throwable(item_data.throwable_type, amount, item_data.max_carry)
		elif item_data.item_type == GameEnums.ConsumableType.AMMO:
			collected = target_player.add_consumable("ammo_box", amount, item_data.max_carry)
		elif item_data.item_type == GameEnums.ConsumableType.TACTICAL:
			collected = target_player.add_consumable(item_data.item_id, amount, item_data.max_carry)
	elif item_name == "Medkit":
		collected = target_player.add_medkits_to_backpack(amount)
	elif item_name == "Ammo":
		collected = target_player.add_consumable("ammo_box", amount)
	elif item_name == "Shotgun":
		var shotgun: WeaponData = load("res://resources/weapons/shotgun_common.tres") as WeaponData
		collected = shotgun != null and target_player.add_weapon_to_inventory(shotgun)
	if not collected:
		return false
	EventBus.consumable_used.emit("拾取：" + _display_name(item_name) + " ×%d" % amount)
	queue_free()
	return true

func _draw() -> void:
	var bob: float = sin(pulse_time * 3.0) * 2.0
	var center: Vector2 = Vector2(0.0, bob)
	var kind: String = _pickup_kind()
	# A small floor beacon gives the item a stable silhouette without using UI artwork.
	_draw_ellipse(Vector2(0.0, 15.0), Vector2(19.0, 6.0), Color(0.01, 0.015, 0.02, 0.60))
	draw_rect(Rect2(-16.0, -13.0 + bob, 32.0, 25.0), Color("081013"), true)
	draw_rect(Rect2(-16.0, -13.0 + bob, 32.0, 25.0), tint, false, 2.0)
	draw_line(Vector2(-12.0, -8.0 + bob), Vector2(12.0, -8.0 + bob), Color(tint, 0.45), 1.0)
	draw_line(Vector2(-12.0, 7.0 + bob), Vector2(12.0, 7.0 + bob), Color(tint, 0.45), 1.0)
	draw_circle(center, 8.0, Color(tint, 0.16))
	match kind:
		"medical":
			draw_rect(Rect2(-2.0, -6.0 + bob, 4.0, 12.0), Color("FFF4E2"), true)
			draw_rect(Rect2(-6.0, -2.0 + bob, 12.0, 4.0), Color("FFF4E2"), true)
		"ammo":
			draw_rect(Rect2(-8.0, -3.0 + bob, 16.0, 7.0), Color("D7E8EA"), true)
			draw_rect(Rect2(-5.0, -1.0 + bob, 10.0, 3.0), tint, true)
		"adrenaline":
			draw_line(Vector2(-5.0, 5.0 + bob), Vector2(5.0, -6.0 + bob), Color("F7E3C1"), 3.0)
			draw_line(Vector2(1.0, -7.0 + bob), Vector2(6.0, -2.0 + bob), Color("F7E3C1"), 2.0)
		"weapon":
			draw_line(Vector2(-9.0, 4.0 + bob), Vector2(8.0, -4.0 + bob), Color("D8E0DE"), 3.0)
			draw_line(Vector2(-5.0, 4.0 + bob), Vector2(-1.0, 9.0 + bob), tint, 3.0)
		"throwable":
			draw_circle(center, 6.0, tint)
			draw_line(Vector2(-2.0, -8.0 + bob), Vector2(3.0, -11.0 + bob), Color("F4E4B7"), 2.0)
		_:
			draw_circle(center, 5.0, tint)
	if _player_nearby:
		draw_string(ThemeDB.fallback_font, Vector2(-48.0, -22.0 + bob), _display_name(item_name), HORIZONTAL_ALIGNMENT_LEFT, -1.0, 10, tint)

func _display_name(value: String) -> String:
	return value.replace("Medkit", "医疗包").replace("Ammo", "弹药").replace("Shotgun", "霰弹枪").replace("Pistol", "手枪").replace("Crowbar", "撬棍").replace("Flare", "信号弹").replace("Smoke", "烟雾弹").replace("Grenade", "手雷").replace("Mine", "地雷").replace("Fine", "精良").replace("Common", "普通").replace("Rare", "稀有").replace("Epic", "史诗").replace("Legendary", "传说").replace("Unknown Weapon", "未知武器").replace("Unknown", "未知物品")

func _pickup_kind() -> String:
	if weapon_data != null:
		return "weapon"
	if item_data != null:
		if item_data.item_type == GameEnums.ConsumableType.HEALING:
			return "medical"
		if item_data.item_type == GameEnums.ConsumableType.AMMO:
			return "ammo"
		if item_data.item_type == GameEnums.ConsumableType.TACTICAL:
			return "adrenaline"
		if item_data.item_type == GameEnums.ConsumableType.THROWABLE:
			return "throwable"
	var normalized: String = item_name.to_lower()
	if normalized.contains("med") or normalized.contains("医疗"):
		return "medical"
	if normalized.contains("ammo") or normalized.contains("弹"):
		return "ammo"
	if normalized.contains("adrenaline") or normalized.contains("肾上腺"):
		return "adrenaline"
	if normalized.contains("shotgun") or normalized.contains("pistol") or normalized.contains("crowbar") or normalized.contains("weapon"):
		return "weapon"
	if normalized.contains("flare") or normalized.contains("smoke") or normalized.contains("grenade") or normalized.contains("mine"):
		return "throwable"
	return "unknown"

func _draw_ellipse(center: Vector2, radius: Vector2, color: Color) -> void:
	var points: PackedVector2Array = PackedVector2Array()
	for index in 24:
		var angle: float = TAU * float(index) / 24.0
		points.append(center + Vector2(cos(angle) * radius.x, sin(angle) * radius.y))
	draw_colored_polygon(points, color)
