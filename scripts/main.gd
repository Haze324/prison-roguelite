extends Node2D

const MONSTER_SCENE: PackedScene = preload("res://scenes/monster.tscn")
const BOSS_DATA: MonsterData = preload("res://resources/monsters/boss_grunt.tres")

@onready var player: Player = $Player
@onready var demon: Monster = $DemonGrunt
@onready var blood_monster: Monster = $BloodMonsterGrunt
@onready var status_label: Label = $HUD/Status
@onready var event_label: Label = $HUD/Event
@onready var noise_manager: NoiseManager = $NoiseManager
@onready var demo_hud: DemoHUD = $HUD/DemoHUD

var _boss: Monster
var _kills: int = 0
var _temporary_noise: float = 0.0
var _residual_noise: float = 0.0
var _last_event: String = "Demo ready"
var _death_timer: float = 0.0
var _run_over: bool = false
var _safehouse_rect := Rect2(260.0, 230.0, 180.0, 140.0)

func _ready() -> void:
	demon.set_target(player)
	blood_monster.set_target(player)
	EventBus.weapon_switched.connect(_on_weapon_switched)
	EventBus.shot_fired.connect(_on_shot_fired)
	EventBus.noise_emitted.connect(_on_noise_emitted)
	EventBus.noise_changed.connect(_on_noise_changed)
	EventBus.dash_started.connect(_on_dash_started)
	EventBus.player_state_changed.connect(_on_state_changed)
	EventBus.monster_alerted.connect(_on_monster_alerted)
	EventBus.monster_killed.connect(_on_monster_killed)
	EventBus.player_died.connect(_on_player_died)
	EventBus.player_parried.connect(_on_player_parried)
	EventBus.consumable_used.connect(_on_consumable_used)
	EventBus.boss_awakened.connect(_on_boss_awakened)
	_spawn_pickup(Vector2(330.0, 480.0), "Medkit", 1, Color(0.85, 0.25, 0.3, 1.0))
	_spawn_pickup(Vector2(760.0, 650.0), "Ammo", 1, Color(0.3, 0.7, 0.9, 1.0))
	_spawn_pickup(Vector2(1180.0, 330.0), "Medkit", 1, Color(0.85, 0.25, 0.3, 1.0))
	_last_event = "WASD move, LMB fire, RMB parry"

func _process(delta: float) -> void:
	if _death_timer > 0.0:
		_death_timer -= delta
		if _death_timer <= 0.0:
			get_tree().reload_current_scene()
			return
	if not _run_over:
		_collect_nearby_pickups()
		if Input.is_action_just_pressed("interact") and _safehouse_rect.has_point(player.global_position):
			player.restore_at_safehouse()
	elif Input.is_action_just_pressed("interact"):
		get_tree().reload_current_scene()
	_update_hud()

func _update_hud() -> void:
	if player == null or status_label == null:
		return
	var weapon_name: String = "None"
	var ammo_text: String = "-"
	if not player.weapons.is_empty():
		var weapon: WeaponData = player.weapons[player.current_weapon_index]
		weapon_name = weapon.weapon_name
		ammo_text = "%d/%d" % [player.current_ammo, weapon.mag_size]
	var current_state: String = "Init"
	if $Player/StateMachine.current_state != null:
		current_state = $Player/StateMachine.current_state.name
	var boss_text: String = "sleeping"
	if _boss != null and is_instance_valid(_boss):
		boss_text = "%.0f/%.0f" % [_boss.current_health, _boss.data.max_health]
	status_label.text = "PRISON ROGUELITE DEMO\n\nHP: %.0f/%.0f   Medkits: %d\nWeapon: %s   Ammo: %s\nState: %s\nNoise: %.0f + %.0f\nKills: %d   Boss: %s\n\nWASD move | Shift dash\nLMB fire | R reload | RMB parry\nQ heal | E resupply in safehouse" % [
		player.current_health,
		player.max_health,
		player.medkits,
		weapon_name,
		ammo_text,
		current_state,
		_temporary_noise,
		_residual_noise,
		_kills,
		boss_text,
	]
	event_label.text = _last_event
	demo_hud.set_data(
		player.current_health,
		player.max_health,
		player.medkits,
		weapon_name,
		player.current_ammo,
		player.weapons[player.current_weapon_index].mag_size if not player.weapons.is_empty() else 0,
		current_state,
		_temporary_noise,
		_residual_noise,
		_kills,
		boss_text,
		_last_event
	)

func _on_shot_fired(weapon_data: WeaponData, position: Vector2, direction: Vector2) -> void:
	var pellet_count: int = maxi(weapon_data.pellets, 1)
	for pellet_index in pellet_count:
		var spread_angle: float = 0.0
		if pellet_count > 1:
			spread_angle = deg_to_rad(randf_range(-weapon_data.spread, weapon_data.spread))
		var projectile: Projectile = Projectile.new()
		add_child(projectile)
		projectile.setup(position, direction.rotated(spread_angle), weapon_data.projectile_speed, weapon_data.damage, player)
	EventBus.noise_emitted.emit(weapon_data.noise, position, player)
	_last_event = "Fired %s (%d pellet%s)" % [weapon_data.weapon_name, pellet_count, "" if pellet_count == 1 else "s"]

func _on_noise_emitted(amount: int, position: Vector2, source: Node2D) -> void:
	for node in get_tree().get_nodes_in_group("monsters"):
		var monster: Monster = node as Monster
		if monster != null and monster != source:
			monster.hear_noise(position, amount)

func _on_noise_changed(temporary: float, residual: float) -> void:
	_temporary_noise = temporary
	_residual_noise = residual

func _on_boss_awakened(_unused: Node2D) -> void:
	if _boss != null or _run_over:
		return
	var boss: Monster = MONSTER_SCENE.instantiate() as Monster
	if boss == null:
		return
	boss.name = "WardenBoss"
	boss.data = BOSS_DATA
	boss.position = Vector2(1400.0, 760.0)
	add_child(boss)
	boss.set_target(player)
	_boss = boss
	_last_event = "BOSS AWAKENED — survive and defeat the Warden"
	EventBus.boss_awakened.emit(boss)

func _spawn_pickup(position: Vector2, item_name: String, amount: int, tint: Color) -> void:
	var pickup: Pickup = Pickup.new()
	add_child(pickup)
	pickup.position = position
	pickup.setup(item_name, amount, tint)

func _collect_nearby_pickups() -> void:
	for node in get_tree().get_nodes_in_group("pickups"):
		var pickup: Pickup = node as Pickup
		if pickup != null and pickup.global_position.distance_to(player.global_position) <= 30.0:
			pickup.collect(player)

func _on_weapon_switched(slot_index: int, weapon_data: WeaponData) -> void:
	_last_event = "Switched weapon #%d: %s" % [slot_index + 1, weapon_data.weapon_name]

func _on_dash_started(_position: Vector2, direction: Vector2) -> void:
	_last_event = "Dash %s" % direction.round()

func _on_state_changed(_previous_state: String, next_state: String) -> void:
	if next_state != "Parry":
		_last_event = "State: " + next_state

func _on_monster_alerted(monster: Node2D, _source: Vector2) -> void:
	_last_event = "%s heard the noise" % monster.name

func _on_monster_killed(monster: Node2D) -> void:
	_kills += 1
	if monster == _boss:
		_run_over = true
		_last_event = "DEMO COMPLETE — press E to start a new run"
	else:
		_last_event = "%s defeated" % monster.name

func _on_player_died() -> void:
	_run_over = true
	_death_timer = 2.0
	_last_event = "YOU DIED — resetting run in 2 seconds"

func _on_player_parried(_attacker: Node2D) -> void:
	_last_event = "Perfect parry!"

func _on_consumable_used(item_name: String) -> void:
	_last_event = "Used / collected: " + item_name
