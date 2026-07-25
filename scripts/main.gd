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
@onready var map_generator: MapGenerator = $MapGenerator
@onready var safehouse: SafehouseMarker = $Safehouse
@onready var merchant: Merchant = $Merchant
@onready var skill_terminal: SkillTerminal = $SkillTerminal

var _boss: Monster
var _kills: int = 0
var _temporary_noise: float = 0.0
var _residual_noise: float = 0.0
var _last_event: String = "Demo ready"
var _death_timer: float = 0.0
var _run_over: bool = false
var _boss_defeated: bool = false
var _power_fixed: int = 0
var _total_power_nodes: int = 3
var _power_seen: Dictionary = {}
var _exit_gate: ExitGate
var _safehouse_rect := Rect2(260.0, 230.0, 180.0, 140.0)

func _ready() -> void:
	demon.set_target(player)
	blood_monster.set_target(player)
	merchant.setup(player)
	skill_terminal.setup(player)
	safehouse.setup(player)
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
	EventBus.boss_phase_changed.connect(_on_boss_phase_changed)
	EventBus.boss_ability_requested.connect(_on_boss_ability_requested)
	EventBus.throwable_thrown.connect(_on_throwable_thrown)
	EventBus.power_node_fixed.connect(_on_power_node_fixed)
	EventBus.run_completed.connect(_on_run_completed)
	EventBus.run_start_requested.connect(_on_run_start_requested)
	EventBus.run_restart_requested.connect(_on_run_restart_requested)
	map_generator.generate()
	_spawn_pickup(Vector2(330.0, 480.0), "Medkit", 1, Color(0.85, 0.25, 0.3, 1.0))
	_spawn_pickup(Vector2(760.0, 650.0), "Ammo", 1, Color(0.3, 0.7, 0.9, 1.0))
	_spawn_pickup(Vector2(1180.0, 330.0), "Medkit", 1, Color(0.85, 0.25, 0.3, 1.0))
	_spawn_pickup(Vector2(1220.0, 700.0), "Shotgun", 1, Color(0.92, 0.62, 0.25, 1.0))
	_spawn_power_nodes()
	_exit_gate = ExitGate.new()
	add_child(_exit_gate)
	_exit_gate.position = Vector2(1500.0, 760.0)
	_exit_gate.setup(player)
	_last_event = "WASD move, Shift run, Space dash, LMB fire"
	demo_hud.show_main_menu()

func _process(delta: float) -> void:
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
		ammo_text = "%d/%d + %d" % [player.current_ammo, weapon.mag_size, player.get_current_reserve_ammo()]
	var current_state: String = "Init"
	if $Player/StateMachine.current_state != null:
		current_state = $Player/StateMachine.current_state.name
	var boss_text: String = "sleeping"
	var boss_health: float = 0.0
	var boss_max_health: float = 1.0
	if _boss != null and is_instance_valid(_boss):
		boss_text = "%.0f/%.0f" % [_boss.current_health, _boss.data.max_health]
		boss_health = _boss.current_health
		boss_max_health = _boss.data.max_health
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
	var armor_current: int = player.armor.durability if player.armor != null else 0
	var armor_maximum: int = player.armor.max_durability if player.armor != null else 0
	var throwable_summary: String = "F%d S%d G%d M%d" % [
		int(player.throwable_counts.get("flare", 0)),
		int(player.throwable_counts.get("smoke", 0)),
		int(player.throwable_counts.get("grenade", 0)),
		int(player.throwable_counts.get("mine", 0)),
	]
	event_label.text = _last_event
	demo_hud.set_data(
		player.current_health,
		player.max_health,
		player.medkits,
		weapon_name,
		player.current_ammo,
		player.weapons[player.current_weapon_index].mag_size if not player.weapons.is_empty() else 0,
		player.get_current_reserve_ammo(),
		current_state,
		_temporary_noise,
		_residual_noise,
		_kills,
		boss_text,
		boss_health,
		boss_max_health,
		_last_event,
		_power_fixed,
		_total_power_nodes,
		armor_current,
		armor_maximum,
		throwable_summary,
		player.get_quick_slot_counts(),
		player.selected_quick_slot,
		MetaProgression.coins,
		MetaProgression.skill_points
	)

func _on_shot_fired(weapon_data: WeaponData, position: Vector2, direction: Vector2) -> void:
	if weapon_data.is_melee:
		_perform_melee_attack(weapon_data, position, direction)
		var melee_noise: int = 0 if weapon_data.effects.has(GameEnums.BuffType.SILENCED) else weapon_data.noise
		EventBus.noise_emitted.emit(melee_noise, position, player)
		_last_event = "Melee strike: %s" % weapon_data.weapon_name
		return
	var pellet_count: int = maxi(weapon_data.pellets, 1)
	if weapon_data.effects.has(GameEnums.BuffType.TWIN_SHOT):
		pellet_count *= 2
	for pellet_index in pellet_count:
		var spread_angle: float = 0.0
		if pellet_count > 1:
			spread_angle = deg_to_rad(randf_range(-weapon_data.spread, weapon_data.spread))
		var projectile: Projectile = Projectile.new()
		add_child(projectile)
		var shot_damage: float = DamageSystem.calculate_weapon_damage(weapon_data, 0.0, player.is_aiming)
		projectile.setup(position, direction.rotated(spread_angle), weapon_data.projectile_speed, shot_damage, player, weapon_data.effects)
	var shot_noise: int = 0 if weapon_data.effects.has(GameEnums.BuffType.SILENCED) else weapon_data.noise
	EventBus.noise_emitted.emit(shot_noise, position, player)
	_last_event = "Fired %s (%d pellet%s)" % [weapon_data.weapon_name, pellet_count, "" if pellet_count == 1 else "s"]

func _on_throwable_thrown(throwable_type: int, position: Vector2, _direction: Vector2, source: Node2D) -> void:
	var throwable: Throwable = Throwable.new()
	add_child(throwable)
	throwable.setup(throwable_type, position, source)
	_last_event = "Throwable deployed: %d" % throwable_type

func _spawn_power_nodes() -> void:
	var positions: Array[Vector2] = [
		Vector2(620.0, 170.0),
		Vector2(1040.0, 760.0),
		Vector2(1320.0, 360.0),
	]
	for index in positions.size():
		var node: PowerNode = PowerNode.new()
		add_child(node)
		node.position = positions[index]
		node.setup(index, player)

func _on_power_node_fixed(node: Node2D, _fixed_count: int, _total_count: int) -> void:
	if node == null or not is_instance_valid(node):
		return
	if _power_seen.has(node.get_instance_id()):
		return
	_power_seen[node.get_instance_id()] = true
	_power_fixed += 1
	var power_node: PowerNode = node as PowerNode
	if power_node != null:
		map_generator.set_power_node_fixed(power_node.node_index)
	EventBus.noise_emitted.emit(95, node.global_position, player)
	_last_event = "Power node %d/%d fixed — noise broadcast" % [_power_fixed, _total_power_nodes]
	if _power_fixed >= _total_power_nodes:
		_last_event = "All power restored — the Warden is awake"
		EventBus.boss_awakened.emit(null)
		if _boss_defeated and _exit_gate != null:
			_exit_gate.set_available(true)

func _on_run_completed(_escaped: bool, _reported_kills: int, _reported_coins: int) -> void:
	if _run_over:
		return
	_run_over = true
	var reward: int = 50 + _kills * 5 + (50 if _boss_defeated else 0)
	MetaProgression.add_coins(reward)
	MetaProgression.add_skill_points(1)
	MetaProgression.record_run("escaped")
	_last_event = "ESCAPED — +%d coins, +1 skill point — press E to run again" % reward
	demo_hud.show_result()

func _perform_melee_attack(weapon_data: WeaponData, position: Vector2, direction: Vector2) -> void:
	var facing: Vector2 = direction.normalized()
	var minimum_dot: float = cos(deg_to_rad(weapon_data.hitbox_angle * 0.5))
	for node in get_tree().get_nodes_in_group("monsters"):
		var monster: Monster = node as Monster
		if monster == null or not is_instance_valid(monster):
			continue
		var offset: Vector2 = monster.global_position - position
		if offset.length() <= weapon_data.hitbox_range and facing.dot(offset.normalized()) >= minimum_dot:
			monster.take_damage(DamageSystem.calculate_weapon_damage(weapon_data, offset.length(), false))

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

func _on_boss_phase_changed(boss: Node2D, phase: int) -> void:
	if boss == _boss:
		_last_event = "WARDEN PHASE %d — telegraphed attack incoming" % phase

func _on_boss_ability_requested(boss: Node2D, ability_type: int, target_position: Vector2) -> void:
	if boss != _boss or _run_over:
		return
	if ability_type == 1:
		_spawn_hazard(target_position, ability_type)
		_last_event = "WARDEN SLAM — leave the warning circle"
		return
	var origin: Vector2 = boss.global_position
	var base_angle: float = origin.angle_to_point(target_position)
	for index in 3:
		var offset: Vector2 = Vector2.from_angle(base_angle + (index - 1) * 0.45) * 110.0
		_spawn_hazard(target_position + offset, ability_type)
	_last_event = "WARDEN ACID SPRAY — three zones marked"

func _spawn_hazard(position: Vector2, hazard_type: int) -> void:
	var hazard := HazardZone.new()
	add_child(hazard)
	hazard.position = position
	hazard.setup(player, hazard_type)

func _spawn_pickup(position: Vector2, item_name: String, amount: int, tint: Color) -> void:
	var pickup: Pickup = Pickup.new()
	add_child(pickup)
	pickup.position = position
	pickup.setup(item_name, amount, tint, player)

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
		_boss_defeated = true
		_run_over = true
		if _exit_gate != null:
			_exit_gate.set_available(_power_fixed >= _total_power_nodes)
		_run_over = false
		_last_event = "WARDEN DEFEATED — reach the extraction gate"
	else:
		_last_event = "%s defeated" % monster.name

func _on_player_died() -> void:
	_run_over = true
	_last_event = "YOU DIED — current run lost"
	demo_hud.show_death()

func _on_run_start_requested() -> void:
	_run_over = false
	demo_hud.show_run()
	_last_event = "Run started — restore power and reach extraction"

func _on_run_restart_requested() -> void:
	get_tree().paused = false
	get_tree().reload_current_scene()

func _on_player_parried(_attacker: Node2D) -> void:
	_last_event = "Perfect parry!"

func _on_consumable_used(item_name: String) -> void:
	_last_event = "Used / collected: " + item_name
