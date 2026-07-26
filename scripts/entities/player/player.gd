class_name Player
extends CharacterBody2D

signal state_changed(previous_state: String, next_state: String)
signal health_changed(current: float, maximum: float)
signal died
signal ammo_changed(current: int, capacity: int)

@export var config: PlayerConfig
@export var weapons: Array[WeaponData] = []
@export var armor: ArmorData
@export var armor_head: ArmorData
@export var armor_hands: ArmorData
@export var armor_body: ArmorData

var max_health: float = 100.0
var current_health: float = 100.0
var armor_reduction: float = 0.15
var medkits: int = 3
var consumable_counts: Dictionary = {
	"ammo_box": 1,
	"adrenaline": 1,
}
var consumable_slot_item: String = "ammo_box"
var throwable_counts: Dictionary = {
	"flare": 1,
	"smoke": 1,
	"grenade": 1,
	"mine": 1,
}
var throwable_slot_items: Array[String] = ["flare", "smoke"]
@export var backpack_capacity: int = 12
var backpack_items: Array[Dictionary] = [
	{"kind": "throwable", "key": "grenade", "name": "手雷", "count": 1},
	{"kind": "throwable", "key": "mine", "name": "地雷", "count": 1},
]
var selected_active_slot: int = 0
var selected_quick_slot: int = 0
var is_dead: bool = false
var is_reloading: bool = false
var current_ammo: int = 0
var ammo_reserves: Dictionary = {}
var magazine_ammo: Dictionary = {}
var _reload_remaining: float = 0.0
var _reload_duration: float = 0.0
var _parry_remaining: float = 0.0
var _parry_direction: Vector2 = Vector2.RIGHT
var _parry_cooldown_remaining: float = 0.0
var _damage_invulnerability: float = 0.0
var _movement_noise_timer: float = 0.0
var _action_visual_remaining: float = 0.0
var _action_visual_type: String = ""
var _muzzle_flash_remaining: float = 0.0
var _melee_swing_remaining: float = 0.0
var _throw_charging: bool = false
var _throw_slot: int = -1
var _throw_charge: float = 0.0
var _throw_charge_duration: float = 0.85
var _adrenaline_remaining: float = 0.0
var _suppress_primary_until_release: bool = false
var _facing_left: bool = false
var _last_move_direction: Vector2 = Vector2.RIGHT
var is_aiming: bool = false

@onready var body_sprite: AnimatedSprite2D = $BodySprite
@onready var shadow: Sprite2D = $Shadow
@onready var weapon_pivot: Node2D = $WeaponPivot
@onready var weapon_sprite: Sprite2D = $WeaponPivot/WeaponSprite
@onready var melee_pivot: Node2D = get_node_or_null("MeleePivot") as Node2D
@onready var melee_sprite: Sprite2D = get_node_or_null("MeleePivot/MeleeSprite") as Sprite2D
@onready var collision_shape: CollisionShape2D = $CollisionShape2D
@onready var state_machine: StateMachine = $StateMachine
@onready var camera: Camera2D = get_node_or_null("Camera2D") as Camera2D
var flashlight_cone: FlashlightCone
var flashlight_light: PointLight2D

var current_weapon_index := 0
var _dash_direction := Vector2.RIGHT
var _dash_remaining := 0.0
var _dash_cooldown_remaining := 0.0
var _dash_requested := false
var _shoot_cooldown_remaining := 0.0
var flashlight_on: bool = true
@export var camera_look_ahead: float = 180.0
@export var aim_speed_multiplier: float = 0.62

func _ready() -> void:
	state_machine.state_changed.connect(_on_state_machine_changed)
	if config == null:
		config = PlayerConfig.new()
	max_health = config.max_health + (20.0 if has_skill("Iron Will") else 0.0)
	current_health = max_health
	if armor_body == null:
		armor_body = armor
	if armor == null:
		armor = armor_body
	if armor != null:
		armor.repair()
		armor_reduction = armor.damage_reduction
	if collision_shape.shape == null:
		var capsule: CapsuleShape2D = CapsuleShape2D.new()
		capsule.radius = config.collision_radius
		capsule.height = config.collision_radius * 2.0
		collision_shape.shape = capsule
	if body_sprite.scale == Vector2.ONE:
		body_sprite.scale = Vector2.ONE * config.body_scale
	shadow.texture = load("res://assets/runtime/character/shadow.png")
	if melee_pivot == null:
		melee_pivot = Node2D.new()
		melee_pivot.name = "MeleePivot"
		melee_pivot.visible = false
		add_child(melee_pivot)
		melee_sprite = Sprite2D.new()
		melee_sprite.name = "MeleeSprite"
		melee_pivot.add_child(melee_sprite)
		melee_sprite.texture = load("res://assets/侧视角/20 melee weapons/20 melee weapons/Crowbar .PNG") as Texture2D
	if body_sprite.sprite_frames == null:
		body_sprite.sprite_frames = SpriteFramesFactory.build_player_frames("res://assets/runtime/character/")
	SpriteFramesFactory.ensure_player_action_animations(body_sprite.sprite_frames, "res://assets/runtime/character/")
	if camera == null:
		camera = Camera2D.new()
		camera.name = "Camera2D"
		camera.position = Vector2.ZERO
		camera.position_smoothing_enabled = true
		camera.position_smoothing_speed = 8.0
		add_child(camera)
	flashlight_cone = FlashlightCone.new()
	flashlight_cone.name = "手电筒光束"
	flashlight_cone.z_index = 0
	flashlight_cone.show_behind_parent = true
	add_child(flashlight_cone)
	_setup_flashlight_light()
	play_body_animation("idle")
	if weapons.is_empty():
		push_warning("Player 没有配置武器资源")
	else:
		for weapon in weapons:
			register_weapon(weapon)
		equip_weapon(0)
	state_machine.start()

func _on_state_machine_changed(previous_state: String, next_state: String) -> void:
	state_changed.emit(previous_state, next_state)
	EventBus.player_state_changed.emit(previous_state, next_state)

func _physics_process(delta: float) -> void:
	if is_dead:
		return
	_dash_cooldown_remaining = maxf(_dash_cooldown_remaining - delta, 0.0)
	_shoot_cooldown_remaining = maxf(_shoot_cooldown_remaining - delta, 0.0)
	_parry_remaining = maxf(_parry_remaining - delta, 0.0)
	_parry_cooldown_remaining = maxf(_parry_cooldown_remaining - delta, 0.0)
	_damage_invulnerability = maxf(_damage_invulnerability - delta, 0.0)
	_movement_noise_timer = maxf(_movement_noise_timer - delta, 0.0)
	_adrenaline_remaining = maxf(_adrenaline_remaining - delta, 0.0)
	var action_was_active: bool = _action_visual_remaining > 0.0
	_action_visual_remaining = maxf(_action_visual_remaining - delta, 0.0)
	_muzzle_flash_remaining = maxf(_muzzle_flash_remaining - delta, 0.0)
	_melee_swing_remaining = maxf(_melee_swing_remaining - delta, 0.0)
	if action_was_active and _action_visual_remaining <= 0.0 and _action_visual_type != "" and not is_reloading:
		_action_visual_type = ""
		play_body_animation("walk" if get_move_direction() != Vector2.ZERO else "idle")
	if is_reloading:
		_reload_remaining = maxf(_reload_remaining - delta, 0.0)
		queue_redraw()
		if _reload_remaining <= 0.0:
			_finish_reload()
	if Input.is_action_just_pressed("reload"):
		reload_weapon()
	if Input.is_action_just_pressed("parry"):
		start_parry()
	if Input.is_action_just_pressed("flashlight"):
		flashlight_on = not flashlight_on
		EventBus.noise_emitted.emit(2, global_position, self)
		queue_redraw()
	if Input.is_action_just_pressed("use_heal"):
		use_medkit()
	if Input.is_action_just_pressed("use_consumable"):
		use_consumable()
	if _suppress_primary_until_release and not Input.is_action_pressed("shoot"):
		_suppress_primary_until_release = false
	_process_throw_input(delta)
	if Input.is_action_just_pressed("dash"):
		_dash_requested = true
	is_aiming = Input.is_action_pressed("aim")
	_update_camera_aim(delta)
	state_machine.physics_update(delta)
	update_aim()
	if Input.is_action_pressed("shoot") and selected_active_slot < 4 and not _suppress_primary_until_release:
		shoot()
	_check_weapon_input()
	queue_redraw()

func get_move_direction() -> Vector2:
	return Input.get_vector("move_left", "move_right", "move_up", "move_down").normalized()

func apply_normal_movement(direction: Vector2, _delta: float) -> void:
	if direction.x != 0.0:
		_last_move_direction = direction
	var running: bool = Input.is_action_pressed("run") and direction != Vector2.ZERO
	var movement_speed: float = config.run_speed if running else config.move_speed
	if is_aiming:
		movement_speed *= aim_speed_multiplier
	if _adrenaline_remaining > 0.0:
		movement_speed *= 1.35
	velocity = direction * movement_speed
	move_and_slide()
	if direction != Vector2.ZERO and _movement_noise_timer <= 0.0:
		var movement_noise: int = config.run_noise if running else config.walk_noise
		if has_skill("Silent Step"):
			movement_noise = maxi(movement_noise - 1, 0)
		EventBus.noise_emitted.emit(movement_noise, global_position, self)
		_movement_noise_timer = 0.35 if running else 0.55

func consume_dash_request() -> bool:
	if not _dash_requested or _dash_cooldown_remaining > 0.0:
		return false
	_dash_requested = false
	return true

func begin_dash() -> void:
	_dash_direction = get_move_direction()
	if _dash_direction == Vector2.ZERO:
		_dash_direction = _last_move_direction
	if _dash_direction == Vector2.ZERO:
		_dash_direction = Vector2.RIGHT
	if _dash_direction.x != 0.0:
		_last_move_direction = _dash_direction
	_dash_remaining = config.dash_duration
	_dash_cooldown_remaining = config.dash_cooldown
	EventBus.dash_started.emit(global_position, _dash_direction)

func apply_dash_movement(delta: float) -> bool:
	_dash_remaining -= delta
	velocity = _dash_direction * config.dash_speed
	move_and_slide()
	return _dash_remaining <= 0.0

func play_body_animation(animation_name: String) -> void:
	if _action_visual_remaining > 0.0 and _action_visual_type != "" and (animation_name == "idle" or animation_name == "walk"):
		return
	if body_sprite.sprite_frames.has_animation(animation_name) and body_sprite.animation != animation_name:
		body_sprite.play(animation_name)

func update_combat_facing() -> void:
	var mouse_direction: Vector2 = get_global_mouse_position() - global_position
	if absf(mouse_direction.x) > 0.001:
		_facing_left = mouse_direction.x < 0.0
		body_sprite.flip_h = _facing_left

func update_aim() -> void:
	var aim: Vector2 = get_global_mouse_position() - global_position
	if aim == Vector2.ZERO:
		return
	if absf(aim.x) > 0.001:
		_facing_left = aim.x < 0.0
		body_sprite.flip_h = _facing_left
	weapon_pivot.position = Vector2(config.hand_offset.x * (1.0 if aim.x >= 0.0 else -1.0), config.hand_offset.y)
	weapon_pivot.rotation = aim.angle()
	weapon_sprite.flip_v = aim.x < 0.0
	var current_weapon: WeaponData = weapons[current_weapon_index] if current_weapon_index >= 0 and current_weapon_index < weapons.size() else null
	var is_melee_weapon: bool = current_weapon != null and current_weapon.is_melee
	weapon_sprite.visible = current_weapon != null and not is_melee_weapon
	if melee_pivot != null:
		melee_pivot.visible = current_weapon != null and is_melee_weapon
		melee_pivot.position = weapon_pivot.position
		var swing_offset: float = 0.0
		if _melee_swing_remaining > 0.0:
			var swing_progress: float = 1.0 - clampf(_melee_swing_remaining / 0.34, 0.0, 1.0)
			swing_offset = lerpf(-1.15, 1.05, swing_progress)
		melee_pivot.rotation = aim.angle() + swing_offset
		if melee_sprite != null:
			_apply_melee_mount(current_weapon)
	if flashlight_cone != null:
		flashlight_cone.position = weapon_pivot.position
		flashlight_cone.set_direction(aim)
		flashlight_cone.set_enabled(flashlight_on)
	if flashlight_light != null:
		flashlight_light.position = weapon_pivot.position
		flashlight_light.rotation = aim.angle()
		flashlight_light.enabled = flashlight_on

func _update_camera_aim(delta: float) -> void:
	if camera == null:
		return
	var viewport_size: Vector2 = get_viewport_rect().size
	var cursor_offset: Vector2 = get_viewport().get_mouse_position() - viewport_size * 0.5
	var normalized_offset: Vector2 = Vector2(
		clampf(cursor_offset.x / maxf(viewport_size.x * 0.5, 1.0), -1.0, 1.0),
		clampf(cursor_offset.y / maxf(viewport_size.y * 0.5, 1.0), -1.0, 1.0)
	)
	var target_offset: Vector2 = normalized_offset * camera_look_ahead if is_aiming else Vector2.ZERO
	camera.position = camera.position.lerp(target_offset, 1.0 - exp(-10.0 * delta))

func shoot() -> void:
	if weapons.is_empty() or _shoot_cooldown_remaining > 0.0 or is_reloading:
		return
	var weapon := weapons[current_weapon_index]
	if weapon == null:
		return
	if weapon.is_melee:
		attack_melee(weapon)
		return
	if weapon.mag_size > 0 and current_ammo <= 0:
		reload_weapon()
		return
	if weapon.mag_size > 0:
		current_ammo -= 1
		magazine_ammo[_weapon_key(weapon)] = current_ammo
		ammo_changed.emit(current_ammo, weapon.mag_size)
	_shoot_cooldown_remaining = weapon.fire_rate
	_muzzle_flash_remaining = 0.08
	queue_redraw()
	var direction := (get_global_mouse_position() - weapon_pivot.global_position).normalized()
	EventBus.shot_fired.emit(weapon, weapon_pivot.global_position, direction)

func attack_melee(weapon: WeaponData) -> void:
	if weapon == null or not weapon.is_melee or is_reloading:
		return
	_shoot_cooldown_remaining = weapon.fire_rate
	_melee_swing_remaining = minf(weapon.fire_rate * 0.65, 0.34)
	_start_action_visual("melee_swing", _melee_swing_remaining)
	queue_redraw()
	var direction: Vector2 = (get_global_mouse_position() - weapon_pivot.global_position).normalized()
	if direction == Vector2.ZERO:
		direction = Vector2.LEFT if _facing_left else Vector2.RIGHT
	EventBus.shot_fired.emit(weapon, weapon_pivot.global_position, direction)

func equip_weapon(index: int) -> void:
	if weapons.is_empty():
		weapon_sprite.texture = null
		weapon_sprite.visible = false
		if melee_pivot != null:
			melee_pivot.visible = false
		ammo_changed.emit(0, 0)
		return
	current_weapon_index = clampi(index, 0, weapons.size() - 1)
	var weapon := weapons[current_weapon_index]
	if weapon == null:
		weapon_sprite.texture = null
		weapon_sprite.visible = false
		if melee_pivot != null:
			melee_pivot.visible = false
		ammo_changed.emit(0, 0)
		return
	is_reloading = false
	_reload_remaining = 0.0
	_reload_duration = 0.0
	_action_visual_remaining = 0.0
	_action_visual_type = ""
	register_weapon(weapon)
	current_ammo = int(magazine_ammo.get(_weapon_key(weapon), weapon.mag_size))
	weapon_sprite.texture = get_weapon_display_icon(current_weapon_index)
	weapon_sprite.scale = Vector2.ONE * weapon.visual_scale
	if melee_sprite != null:
		melee_sprite.texture = get_weapon_display_icon(current_weapon_index)
		_apply_melee_mount(weapon)
	ammo_changed.emit(current_ammo, weapon.mag_size)
	EventBus.weapon_switched.emit(current_weapon_index, weapon)

func _check_weapon_input() -> void:
	if weapons.is_empty():
		return
	if Input.is_action_just_pressed("weapon_1"):
		equip_weapon(0)
	elif Input.is_action_just_pressed("weapon_2"):
		equip_weapon(1)
	elif Input.is_action_just_pressed("weapon_next"):
		equip_weapon((current_weapon_index + 1) % weapons.size())
	elif Input.is_action_just_pressed("weapon_prev"):
		equip_weapon((current_weapon_index - 1 + weapons.size()) % weapons.size())

func reload_weapon() -> void:
	if weapons.is_empty() or is_reloading:
		return
	var weapon := weapons[current_weapon_index]
	if weapon == null:
		return
	var reserve: int = int(ammo_reserves.get(_weapon_key(weapon), weapon.reserve_ammo))
	if weapon.mag_size <= 0 or current_ammo >= weapon.mag_size or reserve <= 0:
		return
	is_reloading = true
	_reload_duration = weapon.reload_time * (0.75 if has_skill("Quick Hands") else 1.0)
	_reload_remaining = _reload_duration
	_start_action_visual("reload", _reload_duration)
	EventBus.noise_emitted.emit(10, global_position, self)

func _finish_reload() -> void:
	is_reloading = false
	_reload_duration = 0.0
	if weapons.is_empty():
		return
	var weapon: WeaponData = weapons[current_weapon_index]
	if weapon == null:
		return
	var key: int = _weapon_key(weapon)
	var reserve: int = int(ammo_reserves.get(key, weapon.reserve_ammo))
	var needed: int = weapon.mag_size - current_ammo
	var loaded: int = mini(needed, reserve)
	current_ammo += loaded
	ammo_reserves[key] = reserve - loaded
	magazine_ammo[key] = current_ammo
	_action_visual_type = ""
	play_body_animation("walk" if get_move_direction() != Vector2.ZERO else "idle")
	ammo_changed.emit(current_ammo, weapon.mag_size)

func start_parry() -> void:
	if weapons.is_empty() or not weapons[current_weapon_index].is_melee or _parry_cooldown_remaining > 0.0 or is_reloading:
		return
	_parry_remaining = 0.2
	_parry_direction = (get_global_mouse_position() - global_position).normalized()
	if _parry_direction == Vector2.ZERO:
		_parry_direction = Vector2.LEFT if _facing_left else Vector2.RIGHT
	_start_action_visual("parry", 0.2)
	_parry_cooldown_remaining = 0.5
	EventBus.player_state_changed.emit("Combat", "Parry")

func is_parrying() -> bool:
	return _parry_remaining > 0.0

func resolve_parry(attacker: Node2D) -> bool:
	if not is_parrying():
		return false
	_parry_remaining = 0.0
	_damage_invulnerability = 0.2
	_start_action_visual("perfect_parry", 0.35)
	EventBus.player_parried.emit(attacker)
	return true

func take_damage(amount: float, attacker: Node2D = null) -> void:
	if is_dead or _damage_invulnerability > 0.0:
		return
	if attacker != null and resolve_parry(attacker):
		return
	_damage_invulnerability = 0.35
	var final_damage: float = amount
	if armor != null:
		final_damage = armor.absorb_damage(amount)
	else:
		final_damage *= 1.0 - armor_reduction
	current_health = maxf(current_health - final_damage, 0.0)
	_start_action_visual("hurt", 0.2)
	EventBus.damage_feedback.emit(self, final_damage, global_position, true)
	if armor != null:
		EventBus.armor_changed.emit(armor.armor_name, armor.durability, armor.max_durability)
	health_changed.emit(current_health, max_health)
	EventBus.player_health_changed.emit(current_health, max_health)
	if current_health <= 0.0:
		is_dead = true
		velocity = Vector2.ZERO
		play_body_animation("death")
		died.emit()
		EventBus.player_died.emit()

func use_medkit() -> bool:
	if medkits <= 0 or is_dead or current_health >= max_health:
		return false
	medkits -= 1
	var heal_amount: float = 50.0 if has_skill("Field Medic") else 35.0
	current_health = minf(current_health + heal_amount, max_health)
	_start_action_visual("heal", 0.8)
	health_changed.emit(current_health, max_health)
	EventBus.player_health_changed.emit(current_health, max_health)
	EventBus.consumable_used.emit("使用回复血瓶")
	return true

func use_consumable() -> bool:
	if is_dead:
		return false
	var count: int = int(consumable_counts.get(consumable_slot_item, 0))
	if count <= 0:
		return false
	if consumable_slot_item == "ammo_box":
		refill_ammo()
	elif consumable_slot_item == "adrenaline":
		_adrenaline_remaining = 6.0
		_start_action_visual("resupply", 0.8)
	else:
		return false
	consumable_counts[consumable_slot_item] = count - 1
	EventBus.consumable_changed.emit(consumable_slot_item, count - 1, 5)
	EventBus.consumable_used.emit("使用" + consumable_display_name(consumable_slot_item))
	return true

func restore_at_safehouse() -> void:
	current_health = max_health
	medkits = 3
	if armor != null:
		armor.repair()
		EventBus.armor_changed.emit(armor.armor_name, armor.durability, armor.max_durability)
	if not weapons.is_empty():
		refill_ammo()
	health_changed.emit(current_health, max_health)
	ammo_changed.emit(current_ammo, weapons[current_weapon_index].mag_size if not weapons.is_empty() else 0)
	EventBus.player_health_changed.emit(current_health, max_health)
	EventBus.consumable_used.emit("安全屋补给完成")
	_start_action_visual("resupply", 0.8)

func register_weapon(weapon: WeaponData) -> void:
	if weapon == null:
		return
	var key: int = _weapon_key(weapon)
	if not ammo_reserves.has(key):
		ammo_reserves[key] = weapon.reserve_ammo
	if not magazine_ammo.has(key):
		magazine_ammo[key] = weapon.mag_size

func refill_ammo() -> void:
	for weapon in weapons:
		register_weapon(weapon)
		var key: int = _weapon_key(weapon)
		ammo_reserves[key] = weapon.reserve_ammo
		magazine_ammo[key] = weapon.mag_size
	if not weapons.is_empty():
		current_ammo = int(magazine_ammo.get(_weapon_key(weapons[current_weapon_index]), 0))
		ammo_changed.emit(current_ammo, weapons[current_weapon_index].mag_size)

func get_current_reserve_ammo() -> int:
	if weapons.is_empty():
		return 0
	return int(ammo_reserves.get(_weapon_key(weapons[current_weapon_index]), 0))

func get_weapon_display_icon(index: int) -> Texture2D:
	if index < 0 or index >= weapons.size():
		return null
	var weapon: WeaponData = weapons[index]
	if weapon == null or weapon.icon == null:
		return null
	if weapon.display_icon != null:
		return weapon.display_icon
	if not weapon.icon.resource_path.to_lower().contains("crowbar .png"):
		weapon.display_icon = weapon.icon
		return weapon.display_icon
	var image: Image = weapon.icon.get_image()
	if image == null or image.is_empty():
		weapon.display_icon = weapon.icon
		return weapon.display_icon
	image.convert(Image.FORMAT_RGBA8)
	var width: int = image.get_width()
	var height: int = image.get_height()
	var background: Color = image.get_pixel(0, 0)
	var queued: PackedByteArray = PackedByteArray()
	queued.resize(width * height)
	var queue: Array[Vector2i] = []
	for x in width:
		_enqueue_background_pixel(image, Vector2i(x, 0), background, queued, queue)
		_enqueue_background_pixel(image, Vector2i(x, height - 1), background, queued, queue)
	for y in height:
		_enqueue_background_pixel(image, Vector2i(0, y), background, queued, queue)
		_enqueue_background_pixel(image, Vector2i(width - 1, y), background, queued, queue)
	var head: int = 0
	while head < queue.size():
		var point: Vector2i = queue[head]
		head += 1
		var pixel: Color = image.get_pixelv(point)
		image.set_pixelv(point, Color(pixel.r, pixel.g, pixel.b, 0.0))
		for neighbor in [point + Vector2i.LEFT, point + Vector2i.RIGHT, point + Vector2i.UP, point + Vector2i.DOWN]:
			if neighbor.x >= 0 and neighbor.x < width and neighbor.y >= 0 and neighbor.y < height:
				_enqueue_background_pixel(image, neighbor, background, queued, queue)
	weapon.display_icon = ImageTexture.create_from_image(image)
	return weapon.display_icon

func _enqueue_background_pixel(image: Image, point: Vector2i, background: Color, queued: PackedByteArray, queue: Array[Vector2i]) -> void:
	var index: int = point.y * image.get_width() + point.x
	if queued[index] != 0:
		return
	var pixel: Color = image.get_pixelv(point)
	if absf(pixel.r - background.r) > 0.11 or absf(pixel.g - background.g) > 0.11 or absf(pixel.b - background.b) > 0.11:
		return
	queued[index] = 1
	queue.append(point)

func _weapon_key(weapon: WeaponData) -> int:
	return weapon.get_instance_id()

func _apply_melee_mount(weapon: WeaponData) -> void:
	if melee_sprite == null or weapon == null:
		return
	melee_sprite.scale = Vector2.ONE * weapon.melee_visual_scale
	melee_sprite.rotation = weapon.melee_rotation_offset
	var scaled_grip_offset: Vector2 = weapon.melee_grip_offset * weapon.melee_visual_scale
	melee_sprite.position = -scaled_grip_offset.rotated(weapon.melee_rotation_offset)
	melee_sprite.flip_v = false

func has_skill(skill_name: String) -> bool:
	return MetaProgression.unlocked_skills.has(skill_name)

func use_throwable(throwable_type: int, inventory_key: String, charge_ratio: float = 1.0) -> bool:
	var count: int = int(throwable_counts.get(inventory_key, 0))
	if count <= 0 or is_dead:
		return false
	if throwable_type == GameEnums.ThrowableType.MINE and charge_ratio < 0.99:
		EventBus.consumable_used.emit("地雷安置失败：需要完成进度")
		return false
	throwable_counts[inventory_key] = count - 1
	var direction: Vector2 = (get_global_mouse_position() - global_position).normalized()
	if direction == Vector2.ZERO:
		direction = Vector2.RIGHT
	var start_position: Vector2 = global_position if throwable_type == GameEnums.ThrowableType.MINE else global_position + direction * 72.0
	EventBus.throwable_thrown.emit(throwable_type, start_position, direction, self, clampf(charge_ratio, 0.2, 1.0))
	_start_action_visual("throw", 0.45)
	EventBus.consumable_changed.emit(inventory_key, count - 1, 1)
	return true

func add_throwable(throwable_type: int, amount: int, maximum: int) -> void:
	var inventory_key: String = throwable_key_for_type(throwable_type)
	var current: int = int(throwable_counts.get(inventory_key, 0))
	throwable_counts[inventory_key] = mini(current + amount, maximum)
	if not throwable_slot_items.has(inventory_key):
		_add_backpack_item("throwable", inventory_key, throwable_display_name(inventory_key), amount)
	EventBus.consumable_changed.emit(inventory_key, int(throwable_counts[inventory_key]), maximum)

func add_consumable(item_key: String, amount: int, maximum: int = 5) -> void:
	var current: int = int(consumable_counts.get(item_key, 0))
	consumable_counts[item_key] = mini(current + amount, maximum)
	if item_key != consumable_slot_item:
		_add_backpack_item("consumable", item_key, consumable_display_name(item_key), amount)
	EventBus.consumable_changed.emit(item_key, int(consumable_counts[item_key]), maximum)

func _add_backpack_item(kind: String, item_key: String, display_name: String, amount: int, extra_record: Dictionary = {}) -> bool:
	for item_index in backpack_items.size():
		var item: Dictionary = backpack_items[item_index]
		var existing_key: String = String(item.get("key", ""))
		if not item.is_empty() and existing_key == item_key and kind != "weapon" and kind != "armor":
			item["count"] = int(item.get("count", 0)) + amount
			return true
	for item_index in backpack_items.size():
		if backpack_items[item_index].is_empty():
			var empty_slot_record: Dictionary = {"kind": kind, "key": item_key, "name": display_name, "count": amount}
			empty_slot_record.merge(extra_record, true)
			backpack_items[item_index] = empty_slot_record
			return true
	if backpack_items.size() >= backpack_capacity:
		return false
	var new_record: Dictionary = {"kind": kind, "key": item_key, "name": display_name, "count": amount}
	new_record.merge(extra_record, true)
	backpack_items.append(new_record)
	return true

func add_weapon_to_inventory(weapon_data: WeaponData) -> bool:
	if weapon_data == null:
		return false
	if weapons.size() < 2:
		weapons.append(weapon_data)
		register_weapon(weapon_data)
		equip_weapon(weapons.size() - 1)
		return true
	var item_key: String = "weapon_pickup_%d" % weapon_data.get_instance_id()
	var display_icon: Texture2D = weapon_data.display_icon if weapon_data.display_icon != null else weapon_data.icon
	return _add_backpack_item("weapon", item_key, weapon_data.weapon_name, 1, {"data": weapon_data, "icon": display_icon})

func consumable_display_name(item_key: String) -> String:
	match item_key:
		"ammo_box":
			return "弹药箱"
		"adrenaline":
			return "肾上腺素"
		_:
			return "消耗品"

func get_throwable_slot_count(slot_index: int) -> int:
	if slot_index < 0 or slot_index >= throwable_slot_items.size():
		return 0
	return int(throwable_counts.get(throwable_slot_items[slot_index], 0))

func get_active_slot_counts() -> Array[int]:
	return [medkits, int(consumable_counts.get(consumable_slot_item, 0)), get_throwable_slot_count(0), get_throwable_slot_count(1)]

func get_active_slot_name(slot_index: int) -> String:
	match slot_index:
		2:
			return "回复血瓶"
		3:
			return consumable_display_name(consumable_slot_item)
		4, 5:
			var throwable_index: int = slot_index - 4
			if throwable_index >= 0 and throwable_index < throwable_slot_items.size():
				return throwable_display_name(throwable_slot_items[throwable_index])
		_:
			return ""
	return ""

func get_inventory_record(slot_id: String) -> Dictionary:
	var record: Dictionary = {}
	if slot_id.begins_with("backpack_"):
		var index_text: String = slot_id.trim_prefix("backpack_")
		var backpack_index: int = int(index_text)
		if backpack_index >= 0 and backpack_index < backpack_items.size():
			return backpack_items[backpack_index].duplicate()
		return record
	match slot_id:
		"weapon_1":
			return _weapon_inventory_record(0)
		"weapon_2":
			return _weapon_inventory_record(1)
		"healing":
			return {"kind": "healing", "key": "medkit", "name": "回复血瓶", "count": medkits}
		"consumable":
			return {"kind": "consumable", "key": consumable_slot_item, "name": consumable_display_name(consumable_slot_item), "count": int(consumable_counts.get(consumable_slot_item, 0))}
		"throwable_1":
			return _throwable_inventory_record(0)
		"throwable_2":
			return _throwable_inventory_record(1)
		"armor_body":
			return {"kind": "armor", "key": "armor_body", "name": armor_body.armor_name if armor_body != null else "空", "count": 1 if armor_body != null else 0, "data": armor_body}
		"armor_head":
			return {"kind": "armor", "key": "armor_head", "name": armor_head.armor_name if armor_head != null else "空", "count": 1 if armor_head != null else 0, "data": armor_head}
		"armor_hands":
			return {"kind": "armor", "key": "armor_hands", "name": armor_hands.armor_name if armor_hands != null else "空", "count": 1 if armor_hands != null else 0, "data": armor_hands}
		_:
			return record

func move_inventory_item(source_id: String, target_id: String) -> bool:
	if source_id == target_id:
		return false
	var source_record: Dictionary = get_inventory_record(source_id)
	if source_record.is_empty() or int(source_record.get("count", 0)) <= 0:
		return false
	var source_is_backpack: bool = source_id.begins_with("backpack_")
	var target_is_backpack: bool = target_id.begins_with("backpack_")
	if source_is_backpack and target_is_backpack:
		var source_index: int = int(source_id.trim_prefix("backpack_"))
		var target_index: int = int(target_id.trim_prefix("backpack_"))
		if source_index < 0 or target_index < 0 or source_index >= backpack_capacity or target_index >= backpack_capacity:
			return false
		if source_index == target_index or source_index >= backpack_items.size():
			return false
		while backpack_items.size() <= target_index:
			backpack_items.append({})
		var target_bag_record: Dictionary = backpack_items[target_index]
		if _inventory_items_stackable(source_record, target_bag_record):
			target_bag_record["count"] = int(target_bag_record.get("count", 0)) + int(source_record.get("count", 0))
			backpack_items[target_index] = target_bag_record
			backpack_items[source_index] = {}
		else:
			backpack_items[source_index] = target_bag_record
			backpack_items[target_index] = source_record
		return true
	if target_id.begins_with("backpack_"):
		if source_id.begins_with("weapon_"):
			return _move_weapon_to_backpack(source_id, target_id)
		var equipment_target_index: int = int(target_id.trim_prefix("backpack_"))
		if equipment_target_index < 0 or equipment_target_index >= backpack_capacity:
			return false
		var target_bag_record: Dictionary = get_inventory_record(target_id)
		if _inventory_items_stackable(source_record, target_bag_record):
			target_bag_record["count"] = int(target_bag_record.get("count", 0)) + int(source_record.get("count", 0))
			_set_backpack_slot(equipment_target_index, target_bag_record)
			_clear_equipment_slot(source_id)
			return true
		if not target_bag_record.is_empty() and int(target_bag_record.get("count", 0)) > 0:
			if not _inventory_slot_accepts(source_id, target_bag_record):
				return false
			_set_backpack_slot(equipment_target_index, source_record)
			_clear_equipment_slot(source_id)
			_apply_equipment_record(source_id, target_bag_record)
			return true
		_set_backpack_slot(equipment_target_index, source_record)
		_clear_equipment_slot(source_id)
		return true
	var target_record: Dictionary = get_inventory_record(target_id)
	if not _inventory_slot_accepts(target_id, source_record):
		return false
	if source_is_backpack:
		var equipment_source_index: int = int(source_id.trim_prefix("backpack_"))
		if equipment_source_index < 0 or equipment_source_index >= backpack_items.size():
			return false
		if not target_record.is_empty() and int(target_record.get("count", 0)) > 0:
			backpack_items[equipment_source_index] = target_record
		else:
			backpack_items[equipment_source_index] = {}
		_apply_equipment_record(target_id, source_record)
		return true
	if not target_record.is_empty() and int(target_record.get("count", 0)) > 0:
		if not _inventory_slot_accepts(source_id, target_record):
			return false
		_clear_equipment_slot(target_id)
		_apply_equipment_record(target_id, source_record)
		_apply_equipment_record(source_id, target_record)
		return true
	_clear_equipment_slot(source_id)
	_apply_equipment_record(target_id, source_record)
	return true

func _inventory_items_stackable(first: Dictionary, second: Dictionary) -> bool:
	if first.is_empty() or second.is_empty():
		return false
	var first_kind: String = String(first.get("kind", ""))
	var second_kind: String = String(second.get("kind", ""))
	var first_key: String = String(first.get("key", ""))
	var second_key: String = String(second.get("key", ""))
	return first_kind == second_kind and first_key == second_key and first_kind != "weapon" and first_kind != "armor"

func _set_backpack_slot(index: int, record: Dictionary) -> void:
	if index < 0 or index >= backpack_capacity:
		return
	while backpack_items.size() <= index:
		backpack_items.append({})
	backpack_items[index] = record

func _move_weapon_to_backpack(source_id: String, target_id: String) -> bool:
	var source_index: int = int(source_id.trim_prefix("weapon_")) - 1
	var target_index: int = int(target_id.trim_prefix("backpack_"))
	if source_index < 0 or source_index >= weapons.size() or target_index < 0 or target_index >= backpack_capacity:
		return false
	var source_record: Dictionary = get_inventory_record(source_id)
	if source_record.is_empty() or int(source_record.get("count", 0)) <= 0:
		return false
	var target_record: Dictionary = get_inventory_record(target_id)
	if not target_record.is_empty() and int(target_record.get("count", 0)) > 0 and String(target_record.get("kind", "")) != "weapon":
		return false
	_set_backpack_slot(target_index, source_record)
	if target_record.is_empty() or int(target_record.get("count", 0)) <= 0:
		_remove_weapon_slot(source_index)
	else:
		_apply_equipment_record("weapon_%d" % (source_index + 1), target_record)
	return true

func _remove_weapon_slot(index: int) -> void:
	if index < 0 or index >= weapons.size():
		return
	weapons.remove_at(index)
	if weapons.is_empty():
		current_weapon_index = 0
		equip_weapon(0)
		return
	if current_weapon_index > index:
		current_weapon_index -= 1
	elif current_weapon_index == index:
		current_weapon_index = mini(current_weapon_index, weapons.size() - 1)
	equip_weapon(current_weapon_index)

func _inventory_slot_accepts(slot_id: String, record: Dictionary) -> bool:
	var kind: String = String(record.get("kind", ""))
	if slot_id == "healing":
		return kind == "healing"
	if slot_id == "consumable":
		return kind == "consumable"
	if slot_id == "throwable_1" or slot_id == "throwable_2":
		return kind == "throwable"
	if slot_id == "armor_head" or slot_id == "armor_hands" or slot_id == "armor_body":
		return kind == "armor"
	if slot_id == "weapon_1" or slot_id == "weapon_2":
		return kind == "weapon"
	return false

func _clear_equipment_slot(slot_id: String) -> void:
	match slot_id:
		"healing":
			medkits = 0
		"consumable":
			consumable_slot_item = ""
		"throwable_1":
			throwable_slot_items[0] = ""
		"throwable_2":
			throwable_slot_items[1] = ""
		"armor_body":
			armor_body = null
			armor = null
			armor_reduction = 0.15
		"armor_head":
			armor_head = null
		"armor_hands":
			armor_hands = null

func _apply_equipment_record(slot_id: String, record: Dictionary) -> void:
	var kind: String = String(record.get("kind", ""))
	var key: String = String(record.get("key", ""))
	var count: int = int(record.get("count", 0))
	match slot_id:
		"healing":
			medkits = count
		"consumable":
			consumable_slot_item = key
			if key != "":
				consumable_counts[key] = count
		"throwable_1", "throwable_2":
			var throwable_index: int = 0 if slot_id == "throwable_1" else 1
			throwable_slot_items[throwable_index] = key
			throwable_counts[key] = count
		"armor_body", "armor_head", "armor_hands":
			if kind == "armor":
				var armor_data: ArmorData = record.get("data") as ArmorData
				if slot_id == "armor_body":
					armor_body = armor_data
					armor = armor_data
					armor_reduction = armor_data.damage_reduction if armor_data != null else 0.15
				elif slot_id == "armor_head":
					armor_head = armor_data
				else:
					armor_hands = armor_data
		"weapon_1", "weapon_2":
			var weapon_data: WeaponData = record.get("data") as WeaponData
			var weapon_index: int = 0 if slot_id == "weapon_1" else 1
			if weapon_data != null and weapon_index < weapons.size():
				weapons[weapon_index] = weapon_data
				register_weapon(weapon_data)
				if current_weapon_index == weapon_index:
					equip_weapon(weapon_index)

func _weapon_inventory_record(index: int) -> Dictionary:
	if index < 0 or index >= weapons.size() or weapons[index] == null:
		return {}
	var weapon_data: WeaponData = weapons[index]
	return {"kind": "weapon", "key": "weapon_%d" % (index + 1), "name": weapon_data.weapon_name, "count": 1, "data": weapon_data, "icon": get_weapon_display_icon(index)}

func _throwable_inventory_record(index: int) -> Dictionary:
	if index < 0 or index >= throwable_slot_items.size() or throwable_slot_items[index] == "":
		return {}
	var key: String = throwable_slot_items[index]
	return {"kind": "throwable", "key": key, "name": throwable_display_name(key), "count": int(throwable_counts.get(key, 0))}

func throwable_display_name(item_key: String) -> String:
	match item_key:
		"flare":
			return "信号弹"
		"smoke":
			return "烟雾弹"
		"grenade":
			return "手雷"
		"mine":
			return "地雷"
		_:
			return "投掷物"

func select_active_slot(slot_index: int, suppress_primary: bool = false) -> void:
	if slot_index < 0 or slot_index > 5:
		return
	selected_active_slot = slot_index
	selected_quick_slot = slot_index
	if suppress_primary:
		_suppress_primary_until_release = true
	if slot_index < 2:
		equip_weapon(slot_index)
	queue_redraw()

func throwable_key_for_type(throwable_type: int) -> String:
	match throwable_type:
		GameEnums.ThrowableType.FLARE:
			return "flare"
		GameEnums.ThrowableType.SMOKE:
			return "smoke"
		GameEnums.ThrowableType.GRENADE:
			return "grenade"
		_:
			return "mine"

func use_quick_slot(slot_index: int) -> bool:
	if slot_index < 0 or slot_index >= throwable_slot_items.size():
		return false
	select_active_slot(slot_index + 4)
	var item_key: String = throwable_slot_items[slot_index]
	var throwable_type: int = throwable_type_for_key(item_key)
	return use_throwable(throwable_type, item_key)

func _process_throw_input(delta: float) -> void:
	_check_active_slot_input()
	if _suppress_primary_until_release:
		return
	if selected_active_slot < 4:
		return
	var throwable_slot: int = selected_active_slot - 4
	if Input.is_action_just_pressed("shoot"):
		_begin_throw_charge(throwable_slot)
	if _throw_charging and Input.is_action_just_released("shoot"):
		_release_throw_charge()
	if _throw_charging:
		_throw_charge = minf(_throw_charge + delta, _throw_charge_duration)
		queue_redraw()

func _begin_throw_charge(slot: int) -> void:
	if slot < 0 or slot >= throwable_slot_items.size() or is_dead:
		return
	var item_key: String = throwable_slot_items[slot]
	if int(throwable_counts.get(item_key, 0)) <= 0:
		return
	selected_active_slot = slot + 4
	selected_quick_slot = slot + 4
	_throw_slot = slot
	_throw_charge = 0.0
	_throw_charging = true
	queue_redraw()

func _release_throw_charge() -> void:
	if not _throw_charging or _throw_slot < 0 or _throw_slot >= throwable_slot_items.size():
		return
	var slot: int = _throw_slot
	var charge_ratio: float = clampf(_throw_charge / _throw_charge_duration, 0.2, 1.0)
	_throw_charging = false
	_throw_slot = -1
	_throw_charge = 0.0
	var item_key: String = throwable_slot_items[slot]
	use_throwable(throwable_type_for_key(item_key), item_key, charge_ratio)
	queue_redraw()

func _check_active_slot_input() -> void:
	if Input.is_action_just_pressed("weapon_1"):
		select_active_slot(0)
	elif Input.is_action_just_pressed("weapon_2"):
		select_active_slot(1)
	elif Input.is_action_just_pressed("throw_flare"):
		select_active_slot(4)
	elif Input.is_action_just_pressed("throw_smoke"):
		select_active_slot(5)
	elif Input.is_action_just_pressed("throw_grenade"):
		select_active_slot(4)
	elif Input.is_action_just_pressed("throw_mine"):
		select_active_slot(5)

func throwable_type_for_key(item_key: String) -> int:
	match item_key:
		"flare":
			return GameEnums.ThrowableType.FLARE
		"smoke":
			return GameEnums.ThrowableType.SMOKE
		"grenade":
			return GameEnums.ThrowableType.GRENADE
		_:
			return GameEnums.ThrowableType.MINE

func get_reload_ratio() -> float:
	if not is_reloading or _reload_duration <= 0.0:
		return 0.0
	return clampf(1.0 - _reload_remaining / _reload_duration, 0.0, 1.0)

func get_quick_slot_counts() -> Array[int]:
	return get_active_slot_counts()

func is_protected_by_safehouse() -> bool:
	for node in get_tree().get_nodes_in_group("safehouses"):
		var safehouse: SafehouseMarker = node as SafehouseMarker
		if safehouse != null and safehouse.contains_point(global_position):
			return true
	return false

func _start_action_visual(visual_type: String, duration: float) -> void:
	_action_visual_type = visual_type
	_action_visual_remaining = duration
	if body_sprite.sprite_frames != null and body_sprite.sprite_frames.has_animation(visual_type):
		body_sprite.play(visual_type)
	queue_redraw()

func _setup_flashlight_light() -> void:
	flashlight_light = PointLight2D.new()
	flashlight_light.name = "手电筒真实光"
	flashlight_light.energy = 0.9
	flashlight_light.color = Color(1.0, 0.88, 0.58, 1.0)
	flashlight_light.shadow_enabled = true
	var image: Image = Image.create(320, 160, false, Image.FORMAT_RGBA8)
	for x in 320:
		var progress: float = clampf((float(x) - 160.0) / 159.0, 0.0, 1.0)
		var spread: float = lerpf(4.0, 72.0, progress)
		for y in 160:
			var distance_from_center: float = absf(float(y) - 80.0)
			var edge: float = clampf((spread - distance_from_center) / maxf(spread * 0.35, 1.0), 0.0, 1.0)
			var alpha: float = 0.0 if x < 160 else edge * (1.0 - progress * 0.82) * 0.9
			image.set_pixel(x, y, Color(1.0, 0.92, 0.62, alpha))
	var texture: ImageTexture = ImageTexture.create_from_image(image)
	flashlight_light.texture = texture
	flashlight_light.texture_scale = 1.15
	add_child(flashlight_light)

func _draw() -> void:
	var health_ratio: float = current_health / maxf(max_health, 1.0)
	draw_rect(Rect2(-30.0, -58.0, 60.0, 6.0), Color(0.04, 0.06, 0.08, 0.9), true)
	draw_rect(Rect2(-30.0, -58.0, 60.0 * clampf(health_ratio, 0.0, 1.0), 6.0), Color(0.95, 0.32, 0.4, 1.0), true)
	draw_rect(Rect2(-30.0, -58.0, 60.0, 6.0), Color(1.0, 0.8, 0.72, 0.8), false, 1.0)
	if is_reloading and _reload_duration > 0.0:
		var reload_ratio: float = 1.0 - _reload_remaining / _reload_duration
		draw_rect(Rect2(-30.0, -70.0, 60.0, 5.0), Color(0.04, 0.06, 0.08, 0.95), true)
		draw_rect(Rect2(-30.0, -70.0, 60.0 * clampf(reload_ratio, 0.0, 1.0), 5.0), Color(1.0, 0.72, 0.24, 1.0), true)
		draw_string(ThemeDB.fallback_font, Vector2(-28.0, -75.0), "换弹", HORIZONTAL_ALIGNMENT_LEFT, -1.0, 9, Color(1.0, 0.82, 0.42, 1.0))
	if _muzzle_flash_remaining > 0.0 and weapon_pivot != null:
		var muzzle: Vector2 = weapon_pivot.position + Vector2.RIGHT.rotated(weapon_pivot.rotation) * 38.0
		draw_circle(muzzle, 8.0, Color(1.0, 0.82, 0.3, 0.85))
		draw_line(muzzle, muzzle + Vector2.RIGHT.rotated(weapon_pivot.rotation) * 18.0, Color(1.0, 0.96, 0.7, 0.9), 3.0)
	if _throw_charging:
		var charge_ratio: float = clampf(_throw_charge / _throw_charge_duration, 0.0, 1.0)
		draw_arc(Vector2.ZERO, 42.0, -PI * 0.5, -PI * 0.5 + TAU * charge_ratio, 28, Color(1.0, 0.72, 0.3, 0.95), 4.0)
		draw_string(ThemeDB.fallback_font, Vector2(-22.0, -82.0), "蓄力 %.0f%%" % (charge_ratio * 100.0), HORIZONTAL_ALIGNMENT_LEFT, -1.0, 9, Color(1.0, 0.82, 0.42, 1.0))
	if _parry_remaining > 0.0:
		var parry_angle: float = _parry_direction.angle()
		draw_arc(Vector2.ZERO, 38.0, parry_angle - 0.72, parry_angle + 0.72, 18, Color(0.45, 0.9, 1.0, 0.9), 4.0)
		draw_line(Vector2.from_angle(parry_angle) * 25.0, Vector2.from_angle(parry_angle) * 48.0, Color(0.8, 1.0, 1.0, 0.95), 3.0)
	if _action_visual_remaining > 0.0:
		var action_color: Color = Color(0.45, 0.92, 0.75, 0.9) if _action_visual_type == "heal" or _action_visual_type == "resupply" else Color(1.0, 0.72, 0.3, 0.9)
		draw_arc(Vector2.ZERO, 30.0, -PI * 0.5, -PI * 0.5 + TAU * clampf(_action_visual_remaining / 0.8, 0.0, 1.0), 20, action_color, 3.0)
		if _action_visual_type == "heal" or _action_visual_type == "resupply":
			draw_line(Vector2(-7.0, 0.0), Vector2(7.0, 0.0), action_color, 3.0)
			draw_line(Vector2(0.0, -7.0), Vector2(0.0, 7.0), action_color, 3.0)
		elif _action_visual_type == "perfect_parry":
			draw_circle(Vector2.ZERO, 18.0, Color(0.45, 0.9, 1.0, 0.2))
