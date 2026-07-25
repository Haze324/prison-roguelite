class_name Monster
extends CharacterBody2D

signal state_changed(previous_state: String, next_state: String)
signal health_changed(current: float, maximum: float)

@export var data: MonsterData

@onready var body_sprite: AnimatedSprite2D = $BodySprite
@onready var collision_shape: CollisionShape2D = $CollisionShape2D
@onready var state_machine: StateMachine = $StateMachine

var target: Node2D
var current_health: float
var patrol_direction := Vector2.RIGHT
var patrol_timer := 0.0
var attack_timer := 0.0
var death_timer := 0.0
var attack_hit_applied := false
var noise_target := Vector2.ZERO
var alert_remaining: float = 0.0
var search_remaining: float = 0.0
var target_lost_remaining: float = 0.0
var boss_wander_remaining: float = 0.0
var boss_wander_direction: Vector2 = Vector2.RIGHT
var boss_phase: int = 1
var boss_transition_remaining: float = 0.0
var boss_ability_cooldown: float = 0.0
var burn_remaining: float = 0.0
var burn_tick_remaining: float = 0.0
var burn_damage: float = 0.0

func _ready() -> void:
	add_to_group("monsters")
	z_index = 2
	state_machine.state_changed.connect(_on_state_changed)
	if data == null:
		data = MonsterData.new()
	current_health = data.max_health
	var capsule := CapsuleShape2D.new()
	capsule.radius = 22.0
	capsule.height = 50.0
	collision_shape.shape = capsule
	body_sprite.scale = Vector2.ONE * data.sprite_scale
	if body_sprite.sprite_frames == null:
		body_sprite.sprite_frames = SpriteFramesFactory.build_monster_frames(data.animation_base_path, data.animation_prefix)
	play_animation("idle")
	state_machine.start()

func _physics_process(delta: float) -> void:
	if burn_remaining > 0.0:
		burn_remaining = maxf(burn_remaining - delta, 0.0)
		burn_tick_remaining -= delta
		if burn_tick_remaining <= 0.0:
			burn_tick_remaining = 0.5
			take_damage(burn_damage)
	if data.is_boss:
		_update_boss_phase(delta)
	state_machine.physics_update(delta)

func set_target(new_target: Node2D) -> void:
	target = new_target

func play_animation(animation_name: String) -> void:
	if body_sprite.sprite_frames != null and body_sprite.sprite_frames.has_animation(animation_name):
		body_sprite.play(animation_name)

func can_detect_target() -> bool:
	return is_instance_valid(target) and global_position.distance_to(target.global_position) <= data.vision_range

func is_target_in_attack_range() -> bool:
	return is_instance_valid(target) and global_position.distance_to(target.global_position) <= data.attack_range

func tick_patrol_timer(delta: float) -> void:
	patrol_timer = maxf(patrol_timer - delta, 0.0)

func begin_patrol() -> void:
	patrol_direction = Vector2.from_angle(randf_range(-PI, PI))
	patrol_timer = randf_range(1.0, 2.5)
	play_animation("walk")

func begin_alert() -> void:
	alert_remaining = 2.5
	velocity = Vector2.ZERO

func advance_alert(delta: float) -> bool:
	alert_remaining = maxf(alert_remaining - delta, 0.0)
	var distance_to_noise: float = global_position.distance_to(noise_target)
	if distance_to_noise > 20.0:
		var direction := global_position.direction_to(noise_target)
		velocity = direction * data.move_speed
		move_and_slide()
		body_sprite.flip_h = direction.x < 0.0
	else:
		velocity = Vector2.ZERO
		play_animation("idle")
	return alert_remaining <= 0.0

func begin_search() -> void:
	search_remaining = 8.0
	patrol_timer = 0.0
	velocity = Vector2.ZERO

func advance_search(delta: float) -> bool:
	search_remaining = maxf(search_remaining - delta, 0.0)
	if global_position.distance_to(noise_target) > 24.0:
		var direction := global_position.direction_to(noise_target)
		velocity = direction * data.move_speed
		move_and_slide()
		body_sprite.flip_h = direction.x < 0.0
	else:
		if patrol_timer <= 0.0:
			patrol_direction = Vector2.from_angle(randf_range(-PI, PI))
			patrol_timer = randf_range(0.6, 1.2)
		velocity = patrol_direction * data.move_speed * 0.45
		move_and_slide()
		body_sprite.flip_h = patrol_direction.x < 0.0
	return search_remaining <= 0.0

func advance_boss_wander(delta: float) -> void:
	if boss_wander_remaining <= 0.0:
		boss_wander_direction = Vector2.from_angle(randf_range(-PI, PI))
		boss_wander_remaining = randf_range(2.0, 4.0)
	boss_wander_remaining = maxf(boss_wander_remaining - delta, 0.0)
	velocity = boss_wander_direction * data.move_speed * 0.65
	move_and_slide()
	body_sprite.flip_h = boss_wander_direction.x < 0.0
	play_animation("idle")

func advance_patrol(delta: float) -> bool:
	patrol_timer = maxf(patrol_timer - delta, 0.0)
	velocity = patrol_direction * data.move_speed
	move_and_slide()
	body_sprite.flip_h = patrol_direction.x < 0.0
	return patrol_timer <= 0.0

func chase_target() -> void:
	if not is_instance_valid(target):
		return
	if target.has_method("is_protected_by_safehouse") and target.is_protected_by_safehouse():
		velocity = Vector2.ZERO
		return
	var direction := global_position.direction_to(target.global_position)
	velocity = direction * data.move_speed
	move_and_slide()
	body_sprite.flip_h = direction.x < 0.0
	play_animation("walk")

func begin_attack() -> void:
	attack_timer = data.attack_duration
	attack_hit_applied = false
	velocity = Vector2.ZERO
	play_animation("attack")
	if is_instance_valid(target):
		body_sprite.flip_h = target.global_position.x < global_position.x

func advance_attack(delta: float) -> bool:
	attack_timer = maxf(attack_timer - delta, 0.0)
	if not attack_hit_applied and attack_timer <= data.attack_duration * 0.45:
		attack_hit_applied = true
		perform_attack()
	return attack_timer <= 0.0

func perform_attack() -> void:
	if not is_instance_valid(target) or global_position.distance_to(target.global_position) > data.attack_range + 12.0:
		return
	if target.has_method("is_protected_by_safehouse") and target.is_protected_by_safehouse():
		return
	if target.has_method("take_damage"):
		target.take_damage(data.attack_damage, self)
	if data.is_boss and boss_ability_cooldown <= 0.0:
		var ability_type: int = 1 if boss_phase == 2 else 2 if boss_phase >= 3 else 0
		if ability_type > 0:
			EventBus.boss_ability_requested.emit(self, ability_type, target.global_position)
			boss_ability_cooldown = 3.2 if ability_type == 1 else 2.4

func advance_death(delta: float) -> bool:
	death_timer += delta
	return death_timer >= 0.7

func take_damage(amount: float) -> void:
	if state_machine.current_state == $StateMachine/Dead or current_health <= 0.0 or boss_transition_remaining > 0.0:
		return
	var final_damage: float = amount * (1.0 - data.natural_armor)
	current_health = maxf(current_health - final_damage, 0.0)
	EventBus.damage_feedback.emit(self, final_damage, global_position, false)
	health_changed.emit(current_health, data.max_health)
	queue_redraw()
	if current_health <= 0.0:
		state_machine.transition_to("Dead")
	else:
		play_animation("hurt")

func apply_burn(damage_per_tick: float, duration: float) -> void:
	burn_damage = maxf(burn_damage, damage_per_tick)
	burn_remaining = maxf(burn_remaining, duration)
	burn_tick_remaining = minf(burn_tick_remaining, 0.1)

func _update_boss_phase(delta: float) -> void:
	boss_transition_remaining = maxf(boss_transition_remaining - delta, 0.0)
	boss_ability_cooldown = maxf(boss_ability_cooldown - delta, 0.0)
	var health_ratio: float = current_health / maxf(data.max_health, 1.0)
	var next_phase: int = 1 if health_ratio > 0.7 else 2 if health_ratio > 0.4 else 3
	if next_phase != boss_phase:
		boss_phase = next_phase
		boss_transition_remaining = 0.8
		EventBus.boss_phase_changed.emit(self, boss_phase)
		queue_redraw()

func _draw() -> void:
	var bar_rect := Rect2(-32.0, -60.0, 64.0, 7.0)
	var health_ratio: float = current_health / maxf(data.max_health, 1.0)
	draw_rect(bar_rect, Color(0.08, 0.03, 0.04, 0.95), true)
	draw_rect(Rect2(bar_rect.position, Vector2(bar_rect.size.x * clampf(health_ratio, 0.0, 1.0), bar_rect.size.y)), Color(0.9, 0.22, 0.28, 1.0), true)
	draw_rect(bar_rect, Color(1.0, 0.72, 0.58, 0.9), false, 1.0)
	draw_string(ThemeDB.fallback_font, Vector2(-38.0, -67.0), data.monster_name.to_upper(), HORIZONTAL_ALIGNMENT_LEFT, 76.0, 10, Color(1.0, 0.78, 0.68, 1.0))
	if data.is_boss:
		draw_string(ThemeDB.fallback_font, Vector2(-38.0, -78.0), "PHASE %d" % boss_phase, HORIZONTAL_ALIGNMENT_LEFT, 76.0, 10, Color(1.0, 0.45, 0.25, 1.0))

func hear_noise(source_position: Vector2, amount: int) -> void:
	if current_health <= 0.0 or not is_instance_valid(target) or amount < data.hearing_threshold:
		return
	if global_position.distance_to(source_position) > data.hearing_range:
		return
	noise_target = source_position
	patrol_direction = global_position.direction_to(source_position)
	patrol_timer = 2.5
	EventBus.monster_alerted.emit(self, source_position)
	if state_machine.current_state == $StateMachine/Dead:
		return
	if data.is_boss:
		target_lost_remaining = 0.0
		if state_machine.current_state.name == "Idle":
			state_machine.transition_to("Chase")
	elif not can_detect_target():
		state_machine.transition_to("Alert")

func _on_state_changed(previous_state: String, next_state: String) -> void:
	state_changed.emit(previous_state, next_state)
	EventBus.monster_state_changed.emit(self, previous_state, next_state)
