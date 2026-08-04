extends Node2D

const MONSTER_SCENE: PackedScene = preload("res://scenes/monster.tscn")
const BOSS_DATA: MonsterData = preload("res://resources/monsters/boss_grunt.tres")
const DAMAGE_POPUP_SCRIPT: Script = preload("res://scripts/entities/damage_popup.gd")
const MEDKIT_DATA: ConsumableData = preload("res://resources/config/consumable_medkit.tres")
const AMMO_BOX_DATA: ConsumableData = preload("res://resources/config/consumable_ammo_box.tres")
const ADRENALINE_DATA: ConsumableData = preload("res://resources/config/consumable_adrenaline.tres")
const FLARE_DATA: ConsumableData = preload("res://resources/consumables/throwable_flare.tres")
const SMOKE_DATA: ConsumableData = preload("res://resources/consumables/throwable_smoke.tres")
const GRENADE_DATA: ConsumableData = preload("res://resources/consumables/throwable_grenade.tres")
const MINE_DATA: ConsumableData = preload("res://resources/consumables/throwable_mine.tres")
const SHOTGUN_DATA: WeaponData = preload("res://resources/weapons/shotgun_common.tres")

@onready var player: Player = $Player
@onready var demon: Monster = $DemonGrunt
@onready var blood_monster: Monster = $BloodMonsterGrunt
@onready var noise_manager: NoiseManager = $NoiseManager
@onready var demo_hud: DemoHUD = $HUD/DemoHUD
@onready var map_manager: MapManager = $MapManager
@onready var interaction_overlay: Node = $HUD/InteractionOverlay
@onready var main_menu_ui: Control = $HUD/MainMenuUI
var merchant: Merchant
var skill_terminal: SkillTerminal
var respawn_point: Node

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
var _pickup_scan_accumulator: float = 0.0
var _hud_update_accumulator: float = 0.0

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
	EventBus.damage_feedback.connect(_on_damage_feedback)
	EventBus.player_parried.connect(_on_player_parried)
	EventBus.consumable_used.connect(_on_consumable_used)
	EventBus.boss_spawn_requested.connect(_on_boss_spawn_requested)
	EventBus.boss_phase_changed.connect(_on_boss_phase_changed)
	EventBus.boss_ability_requested.connect(_on_boss_ability_requested)
	EventBus.throwable_thrown.connect(_on_throwable_thrown)
	EventBus.power_node_fixed.connect(_on_power_node_fixed)
	EventBus.run_completed.connect(_on_run_completed)
	EventBus.run_start_requested.connect(_on_run_start_requested)
	EventBus.run_restart_requested.connect(_on_run_restart_requested)
	interaction_overlay.connect("dialogue_finished", Callable(self, "_on_dialogue_finished"))
	map_manager.load_random_map()
	_bind_map_facilities()
	_bind_map_interactables()
	demo_hud.set_map_label(map_manager.get_display_name())
	var player_spawn: Vector2 = map_manager.get_marker_position("player_spawn")
	if player_spawn != Vector2.ZERO:
		player.position = player_spawn
		if player.camera != null:
			player.camera.reset_smoothing()
	var enemy_spawns: Array[Vector2] = map_manager.get_marker_positions("enemy_spawn")
	if enemy_spawns.size() > 0:
		demon.position = enemy_spawns[0]
	if enemy_spawns.size() > 1:
		blood_monster.position = enemy_spawns[1]
	_spawn_configured_pickups()
	_spawn_power_nodes()
	_exit_gate = ExitGate.new()
	add_child(_exit_gate)
	var exit_position: Vector2 = map_manager.get_marker_position("exit")
	_exit_gate.position = exit_position if exit_position != Vector2.ZERO else Vector2(1500.0, 760.0)
	_exit_gate.setup(player)
	_last_event = "准备行动：移动、射击或打开背包"
	# 主菜单已经拥有独立的动态封面和交互组件；运行 HUD 只在进入任务后显示。
	if main_menu_ui != null and main_menu_ui.visible:
		demo_hud.hide()
	else:
		demo_hud.show_main_menu()

func _process(delta: float) -> void:
	if not _run_over:
		_pickup_scan_accumulator += delta
		if _pickup_scan_accumulator >= 0.08:
			_pickup_scan_accumulator = 0.0
			_collect_nearby_pickups()
		if Input.is_action_just_pressed("interact"):
			_try_interact_with_map_doors()
	elif Input.is_action_just_pressed("interact"):
		get_tree().reload_current_scene()
	_hud_update_accumulator += delta
	if _hud_update_accumulator >= 0.05:
		_hud_update_accumulator = 0.0
		_update_hud()

func _bind_map_facilities() -> void:
	if map_manager.active_map == null:
		return
	var merchants: Array[Node] = map_manager.active_map.find_children("*", "Merchant", true, false)
	if not merchants.is_empty():
		merchant = merchants[0] as Merchant
		merchant.setup(player)
	var terminals: Array[Node] = map_manager.active_map.find_children("*", "SkillTerminal", true, false)
	if not terminals.is_empty():
		skill_terminal = terminals[0] as SkillTerminal
		skill_terminal.setup(player)
	respawn_point = map_manager.active_map.get_node_or_null("Facilities/RespawnPoint")
	if respawn_point != null:
		respawn_point.call("setup", player)

func _bind_map_interactables() -> void:
	if map_manager.active_map == null:
		return
	var corpse: Node = map_manager.active_map.get_node_or_null("Facilities/Corpse")
	if corpse != null and corpse.has_signal("interaction_requested"):
		corpse.call("setup", player)
		var corpse_callback: Callable = Callable(self, "_on_corpse_interact")
		if not corpse.is_connected("interaction_requested", corpse_callback):
			corpse.connect("interaction_requested", corpse_callback)
	if merchant != null and merchant.has_signal("interaction_requested"):
		var merchant_callback: Callable = Callable(self, "_on_merchant_interact")
		if not merchant.interaction_requested.is_connected(merchant_callback):
			merchant.interaction_requested.connect(merchant_callback)

func _on_corpse_interact(corpse: Node2D) -> void:
	if interaction_overlay == null or not is_instance_valid(interaction_overlay):
		return
	interaction_overlay.call(
		"open_corpse_dialogue",
		corpse,
		load("res://assets/俯视角/The Female Adventurer - Free/The Female Adventurer - Free/Death/death.png"),
		int(corpse.get("portrait_frame")),
	)

func _on_merchant_interact(target: Node2D) -> void:
	if target is Merchant and interaction_overlay != null:
		interaction_overlay.call("open_merchant_dialogue", target)

func _on_dialogue_finished(dialogue_kind: String, target: Node) -> void:
	if dialogue_kind == "corpse" and target != null and is_instance_valid(target):
		player.add_access_pass("prison_pass")
		target.call("mark_searched")
		_last_event = "从尸体上找到通信证：部分封锁门已可通行"

func _try_interact_with_map_doors() -> void:
	if map_manager.active_map == null:
		return
	for node in map_manager.active_map.find_children("*", "MapDoor", true, false):
		var door: MapDoor = node as MapDoor
		if door == null or door.opened:
			continue
		var reach: float = maxf(42.0, maxf(door.size.x, door.size.y) * 0.75)
		if door.global_position.distance_to(player.global_position) <= reach:
			door.try_open(player)

func _update_hud() -> void:
	if player == null or demo_hud == null:
		return
	var weapon_name: String = "None"
	if not player.weapons.is_empty():
		var weapon: WeaponData = player.weapons[player.current_weapon_index]
		weapon_name = weapon.weapon_name
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
	var armor_current: int = player.armor.durability if player.armor != null else 0
	var armor_maximum: int = player.armor.max_durability if player.armor != null else 0
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
		"",
		player.get_quick_slot_counts(),
		player.selected_active_slot,
		MetaProgression.coins,
		MetaProgression.skill_points,
		player.get_weapon_display_icon(0),
		player.get_weapon_display_icon(1),
		player.current_weapon_index,
		player.get_reload_ratio(),
		player.consumable_display_name(player.consumable_slot_item),
		[player.throwable_display_name(player.throwable_slot_items[0]), player.throwable_display_name(player.throwable_slot_items[1])]
	)

func _on_shot_fired(weapon_data: WeaponData, position: Vector2, direction: Vector2) -> void:
	if weapon_data.is_melee:
		_perform_melee_attack(weapon_data, position, direction)
		var melee_noise: int = 0 if weapon_data.effects.has(GameEnums.BuffType.SILENCED) else weapon_data.noise
		EventBus.noise_emitted.emit(melee_noise, position, player)
		_last_event = "近战攻击：%s" % weapon_data.weapon_name
		return
	var pellet_count: int = maxi(weapon_data.pellets, 1)
	if weapon_data.effects.has(GameEnums.BuffType.TWIN_SHOT):
		pellet_count *= 2
	for pellet_index in pellet_count:
		var spread_angle: float = 0.0
		if pellet_count > 1:
			var spread_multiplier: float = weapon_data.aim_spread_multiplier if player.is_aiming else 1.0
			var effective_spread: float = weapon_data.spread * spread_multiplier
			spread_angle = deg_to_rad(randf_range(-effective_spread, effective_spread))
		var projectile: Projectile = Projectile.new()
		add_child(projectile)
		var shot_damage: float = DamageSystem.calculate_weapon_damage(weapon_data, 0.0, player.is_aiming)
		projectile.setup(position, direction.rotated(spread_angle), weapon_data.projectile_speed, shot_damage, player, weapon_data.effects, weapon_data.range)
	var shot_noise: int = 0 if weapon_data.effects.has(GameEnums.BuffType.SILENCED) else weapon_data.noise
	EventBus.noise_emitted.emit(shot_noise, position, player)

func _on_throwable_thrown(throwable_type: int, position: Vector2, direction: Vector2, source: Node2D, charge_ratio: float) -> void:
	var throwable: Throwable = Throwable.new()
	add_child(throwable)
	throwable.setup(throwable_type, position, source, direction, charge_ratio)
	_last_event = "投掷物已释放"

func _spawn_power_nodes() -> void:
	for existing in get_tree().get_nodes_in_group("power_nodes"):
		if existing != null and is_instance_valid(existing):
			existing.queue_free()
	_power_seen.clear()
	_power_fixed = 0
	var positions: Array[Vector2] = map_manager.get_marker_positions("power")
	if positions.size() < _total_power_nodes:
		positions = [Vector2(620.0, 170.0), Vector2(1040.0, 760.0), Vector2(1320.0, 360.0)]
	_total_power_nodes = positions.size()
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
	if power_node != null and map_manager.active_map != null:
		map_manager.active_map.set_meta("power_fixed_%d" % power_node.node_index, true)
	EventBus.noise_emitted.emit(95, node.global_position, player)
	_last_event = "电源 %d / %d 已修复，噪声正在扩散" % [_power_fixed, _total_power_nodes]
	if _power_fixed >= _total_power_nodes:
		_last_event = "全部电力已恢复，守卫者已经苏醒"
		_unlock_map_doors()
		EventBus.boss_spawn_requested.emit()
		if _boss_defeated and _exit_gate != null:
			_exit_gate.set_available(true)

func _unlock_map_doors() -> void:
	for node in get_tree().get_nodes_in_group("map_doors"):
		var door: MapDoor = node as MapDoor
		if door != null:
			door.unlock_from_power()

func _on_run_completed(_escaped: bool, _reported_kills: int, _reported_coins: int) -> void:
	if _run_over:
		return
	_run_over = true
	var reward: int = 50 + _kills * 5 + (50 if _boss_defeated else 0)
	MetaProgression.add_coins(reward)
	MetaProgression.add_skill_points(1)
	MetaProgression.record_run("escaped")
	_last_event = "已成功撤离：硬币 +%d，技能点 +1" % reward
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

func _on_boss_spawn_requested() -> void:
	if _boss != null or _run_over:
		return
	var boss: Monster = MONSTER_SCENE.instantiate() as Monster
	if boss == null:
		return
	boss.name = "WardenBoss"
	boss.data = BOSS_DATA
	boss.position = map_manager.get_marker_position("boss_spawn")
	if boss.position == Vector2.ZERO:
		boss.position = Vector2(1400.0, 760.0)
	add_child(boss)
	boss.set_target(player)
	_boss = boss
	_last_event = "守卫者已苏醒：活下来并击败它"
	demo_hud.flash_boss_alert()
	EventBus.boss_awakened.emit(boss)

func _on_boss_phase_changed(boss: Node2D, phase: int) -> void:
	if boss == _boss:
		_last_event = "守卫者进入第 %d 阶段，准备躲避攻击" % phase
		demo_hud.flash_boss_alert(0.9)

func _on_boss_ability_requested(boss: Node2D, ability_type: int, target_position: Vector2) -> void:
	if boss != _boss or _run_over:
		return
	if ability_type == 1:
		_spawn_hazard(target_position, ability_type)
		_last_event = "守卫者重击：离开警示区域"
		return
	var origin: Vector2 = boss.global_position
	var base_angle: float = origin.angle_to_point(target_position)
	for index in 3:
		var offset: Vector2 = Vector2.from_angle(base_angle + (index - 1) * 0.45) * 110.0
		_spawn_hazard(target_position + offset, ability_type)
	_last_event = "守卫者酸液喷射：三个危险区域已标记"

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

func _spawn_data_pickup(position: Vector2, data: ConsumableData, amount: int, tint: Color) -> void:
	var pickup: Pickup = Pickup.new()
	add_child(pickup)
	pickup.position = position
	pickup.setup_data(data, amount, tint, player)

func _spawn_weapon_pickup(position: Vector2, data: WeaponData, tint: Color) -> void:
	var pickup: Pickup = Pickup.new()
	add_child(pickup)
	pickup.position = position
	pickup.setup_weapon(data, tint, player)

func _spawn_configured_pickups() -> void:
	var markers: Array[MapMarker] = map_manager.get_markers("pickup")
	if markers.is_empty():
		_spawn_data_pickup(Vector2(330.0, 480.0), MEDKIT_DATA, 1, Color(0.85, 0.25, 0.3, 1.0))
		return
	for marker in markers:
		match marker.payload:
			"medkit":
				_spawn_data_pickup(marker.global_position, MEDKIT_DATA, 1, Color(0.85, 0.25, 0.3, 1.0))
			"ammo_box":
				_spawn_data_pickup(marker.global_position, AMMO_BOX_DATA, 1, Color(0.3, 0.7, 0.9, 1.0))
			"adrenaline":
				_spawn_data_pickup(marker.global_position, ADRENALINE_DATA, 1, Color(0.95, 0.55, 0.2, 1.0))
			"shotgun":
				var generated_shotgun: WeaponData = WeaponGenerator.generate_random(SHOTGUN_DATA, map_manager.map_seed)
				_spawn_weapon_pickup(marker.global_position, generated_shotgun, Color(0.78, 0.45, 0.95, 1.0))
			"flare":
				_spawn_data_pickup(marker.global_position, FLARE_DATA, 1, Color(1.0, 0.78, 0.28, 1.0))
			"smoke":
				_spawn_data_pickup(marker.global_position, SMOKE_DATA, 1, Color(0.65, 0.7, 0.78, 1.0))
			"grenade":
				_spawn_data_pickup(marker.global_position, GRENADE_DATA, 1, Color(0.95, 0.3, 0.2, 1.0))
			"mine":
				_spawn_data_pickup(marker.global_position, MINE_DATA, 1, Color(0.75, 0.25, 0.85, 1.0))

func _collect_nearby_pickups() -> void:
	for node in get_tree().get_nodes_in_group("pickups"):
		var pickup: Pickup = node as Pickup
		if pickup != null and pickup.global_position.distance_to(player.global_position) <= 30.0:
			pickup.collect(player)

func _on_weapon_switched(slot_index: int, _weapon_data: WeaponData) -> void:
	_last_event = "已切换武器 %d" % (slot_index + 1)

func _on_dash_started(_position: Vector2, _direction: Vector2) -> void:
	_last_event = "冲刺"

func _on_state_changed(_previous_state: String, next_state: String) -> void:
	if next_state == "Parry":
		_last_event = "格挡窗口"

func _on_monster_alerted(monster: Node2D, _source: Vector2) -> void:
	_last_event = "%s 听到了噪声" % monster.name

func _on_monster_killed(monster: Node2D) -> void:
	_kills += 1
	if monster == _boss:
		_boss_defeated = true
		_run_over = true
		if _exit_gate != null:
			_exit_gate.set_available(_power_fixed >= _total_power_nodes)
		_run_over = false
		_last_event = "守卫者已击败，前往撤离门"
	else:
		_last_event = "%s 已被击败" % monster.name

func _on_player_died() -> void:
	if player.respawn_at_checkpoint():
		_run_over = false
		_last_event = "已在复活点重生"
		demo_hud.show_run()
		return
	_run_over = true
	_last_event = "任务失败，本局携带物资已丢失"
	demo_hud.show_death()

func _on_run_start_requested() -> void:
	_run_over = false
	if main_menu_ui != null:
		main_menu_ui.visible = false
	demo_hud.show_run()
	_last_event = "任务开始：修复电力并抵达撤离点"

func _on_run_restart_requested() -> void:
	if main_menu_ui != null:
		main_menu_ui.visible = false
	get_tree().paused = false
	get_tree().reload_current_scene()

func _on_player_parried(_attacker: Node2D) -> void:
	_last_event = "完美格挡！"

func _on_damage_feedback(_target: Node2D, amount: float, position: Vector2, is_player: bool) -> void:
	var popup: DamagePopup = DAMAGE_POPUP_SCRIPT.new() as DamagePopup
	if popup == null:
		return
	add_child(popup)
	var tint: Color = Color(1.0, 0.35, 0.38, 1.0) if is_player else Color(1.0, 0.82, 0.3, 1.0)
	popup.setup(amount, position, tint)

func _on_consumable_used(item_name: String) -> void:
	_last_event = "已使用 / 拾取：" + item_name
