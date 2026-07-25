class_name Player
extends CharacterBody2D

signal state_changed(previous_state: String, next_state: String)
signal health_changed(current: float, maximum: float)
signal died
signal ammo_changed(current: int, capacity: int)

@export var config: PlayerConfig
@export var weapons: Array[WeaponData] = []
@export var armor: ArmorData

var max_health: float = 100.0
var current_health: float = 100.0
var armor_reduction: float = 0.15
var medkits: int = 3
var throwable_counts: Dictionary = {
	"flare": 1,
	"smoke": 1,
	"grenade": 1,
	"mine": 1,
}
var is_dead: bool = false
var is_reloading: bool = false
var current_ammo: int = 0
var ammo_reserves: Dictionary = {}
var magazine_ammo: Dictionary = {}
var _reload_remaining: float = 0.0
var _parry_remaining: float = 0.0
var _parry_cooldown_remaining: float = 0.0
var _damage_invulnerability: float = 0.0
var _movement_noise_timer: float = 0.0
var is_aiming: bool = false

@onready var body_sprite: AnimatedSprite2D = $BodySprite
@onready var shadow: Sprite2D = $Shadow
@onready var weapon_pivot: Node2D = $WeaponPivot
@onready var weapon_sprite: Sprite2D = $WeaponPivot/WeaponSprite
@onready var collision_shape: CollisionShape2D = $CollisionShape2D
@onready var state_machine: StateMachine = $StateMachine

var current_weapon_index := 0
var _dash_direction := Vector2.RIGHT
var _dash_remaining := 0.0
var _dash_cooldown_remaining := 0.0
var _dash_requested := false
var _shoot_cooldown_remaining := 0.0
var flashlight_on: bool = true

func _ready() -> void:
	state_machine.state_changed.connect(_on_state_machine_changed)
	if config == null:
		config = PlayerConfig.new()
	max_health = config.max_health
	current_health = max_health
	if armor != null:
		armor.repair()
		armor_reduction = armor.damage_reduction
	var capsule := CapsuleShape2D.new()
	capsule.radius = config.collision_radius
	capsule.height = config.collision_radius * 2.0
	collision_shape.shape = capsule
	body_sprite.scale = Vector2.ONE * config.body_scale
	shadow.texture = load("res://assets/runtime/character/shadow.png")
	if body_sprite.sprite_frames == null:
		body_sprite.sprite_frames = SpriteFramesFactory.build_player_frames("res://assets/runtime/character/")
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
	if is_reloading:
		_reload_remaining = maxf(_reload_remaining - delta, 0.0)
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
	if Input.is_action_just_pressed("throw_flare"):
		use_throwable(GameEnums.ThrowableType.FLARE, "flare")
	elif Input.is_action_just_pressed("throw_smoke"):
		use_throwable(GameEnums.ThrowableType.SMOKE, "smoke")
	elif Input.is_action_just_pressed("throw_grenade"):
		use_throwable(GameEnums.ThrowableType.GRENADE, "grenade")
	elif Input.is_action_just_pressed("throw_mine"):
		use_throwable(GameEnums.ThrowableType.MINE, "mine")
	if Input.is_action_just_pressed("dash"):
		_dash_requested = true
	state_machine.physics_update(delta)
	update_aim()
	is_aiming = Input.is_action_pressed("aim")
	if Input.is_action_pressed("shoot"):
		shoot()
	_check_weapon_input()

func get_move_direction() -> Vector2:
	return Input.get_vector("move_left", "move_right", "move_up", "move_down").normalized()

func apply_normal_movement(direction: Vector2, _delta: float) -> void:
	var running: bool = Input.is_action_pressed("run") and direction != Vector2.ZERO
	var movement_speed: float = config.run_speed if running else config.move_speed
	velocity = direction * movement_speed
	move_and_slide()
	if direction != Vector2.ZERO and _movement_noise_timer <= 0.0:
		var movement_noise: int = config.run_noise if running else config.walk_noise
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
		_dash_direction = (get_global_mouse_position() - global_position).normalized()
	if _dash_direction == Vector2.ZERO:
		_dash_direction = Vector2.RIGHT
	_dash_remaining = config.dash_duration
	_dash_cooldown_remaining = config.dash_cooldown
	EventBus.dash_started.emit(global_position, _dash_direction)

func apply_dash_movement(delta: float) -> bool:
	_dash_remaining -= delta
	velocity = _dash_direction * config.dash_speed
	move_and_slide()
	return _dash_remaining <= 0.0

func play_body_animation(animation_name: String) -> void:
	if body_sprite.sprite_frames.has_animation(animation_name) and body_sprite.animation != animation_name:
		body_sprite.play(animation_name)

func update_combat_facing() -> void:
	var direction := get_global_mouse_position() - global_position
	if direction.x == 0.0:
		direction.x = 1.0 if not body_sprite.flip_h else -1.0
	body_sprite.flip_h = direction.x < 0.0

func update_aim() -> void:
	var aim := get_global_mouse_position() - global_position
	if aim == Vector2.ZERO:
		return
	weapon_pivot.position = Vector2(config.hand_offset.x * (1.0 if aim.x >= 0.0 else -1.0), config.hand_offset.y)
	weapon_pivot.rotation = aim.angle()
	weapon_sprite.flip_v = aim.x < 0.0
	body_sprite.flip_h = aim.x < 0.0

func shoot() -> void:
	if weapons.is_empty() or _shoot_cooldown_remaining > 0.0 or is_reloading:
		return
	var weapon := weapons[current_weapon_index]
	if weapon.mag_size > 0 and current_ammo <= 0:
		reload_weapon()
		return
	if weapon.mag_size > 0:
		current_ammo -= 1
		magazine_ammo[_weapon_key(weapon)] = current_ammo
		ammo_changed.emit(current_ammo, weapon.mag_size)
	_shoot_cooldown_remaining = weapon.fire_rate
	var direction := (get_global_mouse_position() - weapon_pivot.global_position).normalized()
	EventBus.shot_fired.emit(weapon, weapon_pivot.global_position, direction)

func equip_weapon(index: int) -> void:
	if weapons.is_empty():
		return
	current_weapon_index = clampi(index, 0, weapons.size() - 1)
	var weapon := weapons[current_weapon_index]
	is_reloading = false
	_reload_remaining = 0.0
	register_weapon(weapon)
	current_ammo = int(magazine_ammo.get(_weapon_key(weapon), weapon.mag_size))
	weapon_sprite.texture = weapon.icon
	ammo_changed.emit(current_ammo, weapon.mag_size)
	EventBus.weapon_switched.emit(current_weapon_index, weapon)

func _check_weapon_input() -> void:
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
	var reserve: int = int(ammo_reserves.get(_weapon_key(weapon), weapon.reserve_ammo))
	if weapon.mag_size <= 0 or current_ammo >= weapon.mag_size or reserve <= 0:
		return
	is_reloading = true
	_reload_remaining = weapon.reload_time
	EventBus.noise_emitted.emit(10, global_position, self)

func _finish_reload() -> void:
	is_reloading = false
	if weapons.is_empty():
		return
	var weapon: WeaponData = weapons[current_weapon_index]
	var key: int = _weapon_key(weapon)
	var reserve: int = int(ammo_reserves.get(key, weapon.reserve_ammo))
	var needed: int = weapon.mag_size - current_ammo
	var loaded: int = mini(needed, reserve)
	current_ammo += loaded
	ammo_reserves[key] = reserve - loaded
	magazine_ammo[key] = current_ammo
	ammo_changed.emit(current_ammo, weapon.mag_size)

func start_parry() -> void:
	if weapons.is_empty() or not weapons[current_weapon_index].is_melee or _parry_cooldown_remaining > 0.0 or is_reloading:
		return
	_parry_remaining = 0.2
	_parry_cooldown_remaining = 0.5
	EventBus.player_state_changed.emit("Combat", "Parry")

func is_parrying() -> bool:
	return _parry_remaining > 0.0

func resolve_parry(attacker: Node2D) -> bool:
	if not is_parrying():
		return false
	_parry_remaining = 0.0
	_damage_invulnerability = 0.2
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
	current_health = minf(current_health + 35.0, max_health)
	health_changed.emit(current_health, max_health)
	EventBus.player_health_changed.emit(current_health, max_health)
	EventBus.consumable_used.emit("Medkit")
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
	EventBus.consumable_used.emit("Safehouse resupply")

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

func _weapon_key(weapon: WeaponData) -> int:
	return weapon.get_instance_id()

func use_throwable(throwable_type: int, inventory_key: String) -> bool:
	var count: int = int(throwable_counts.get(inventory_key, 0))
	if count <= 0 or is_dead:
		return false
	throwable_counts[inventory_key] = count - 1
	var direction: Vector2 = (get_global_mouse_position() - global_position).normalized()
	if direction == Vector2.ZERO:
		direction = Vector2.RIGHT
	EventBus.throwable_thrown.emit(throwable_type, global_position + direction * 72.0, direction, self)
	EventBus.consumable_changed.emit(inventory_key, count - 1, 1)
	return true

func is_protected_by_safehouse() -> bool:
	for node in get_tree().get_nodes_in_group("safehouses"):
		var safehouse: SafehouseMarker = node as SafehouseMarker
		if safehouse != null and safehouse.contains_point(global_position):
			return true
	return false

func _draw() -> void:
	if not flashlight_on or weapon_pivot == null:
		return
	var direction: Vector2 = Vector2.RIGHT.rotated(weapon_pivot.rotation)
	var points := PackedVector2Array([
		Vector2.ZERO,
		direction.rotated(-0.32) * 210.0,
		direction.rotated(0.32) * 210.0,
	])
	draw_colored_polygon(points, Color(1.0, 0.9, 0.62, 0.06))
	draw_arc(Vector2.ZERO, 210.0, direction.angle() - 0.32, direction.angle() + 0.32, 18, Color(1.0, 0.9, 0.62, 0.22), 1.5)
