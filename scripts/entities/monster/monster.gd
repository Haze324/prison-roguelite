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

func _ready() -> void:
    add_to_group("monsters")
    state_machine.state_changed.connect(_on_state_changed)
	if data == null:
		data = MonsterData.new()
	current_health = data.max_health
	var capsule := CapsuleShape2D.new()
	capsule.radius = 22.0
	capsule.height = 50.0
	collision_shape.shape = capsule
	body_sprite.scale = Vector2.ONE * data.sprite_scale
	body_sprite.sprite_frames = SpriteFramesFactory.build_monster_frames(data.animation_base_path, data.animation_prefix)
	play_animation("idle")
	state_machine.start()

func _physics_process(delta: float) -> void:
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

func advance_patrol(delta: float) -> bool:
	patrol_timer = maxf(patrol_timer - delta, 0.0)
	velocity = patrol_direction * data.move_speed
	move_and_slide()
	body_sprite.flip_h = patrol_direction.x < 0.0
	return patrol_timer <= 0.0

func chase_target() -> void:
	if not is_instance_valid(target):
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
	if target.has_method("take_damage"):
		target.take_damage(12.0, self)

func advance_death(delta: float) -> bool:
	death_timer += delta
	return death_timer >= 0.7

func take_damage(amount: float) -> void:
	if state_machine.current_state == $StateMachine/Dead or current_health <= 0.0:
		return
	current_health = maxf(current_health - amount, 0.0)
	health_changed.emit(current_health, data.max_health)
	if current_health <= 0.0:
		state_machine.transition_to("Dead")
	else:
		play_animation("hurt")

func hear_noise(source_position: Vector2, amount: int) -> void:
	if current_health <= 0.0 or not is_instance_valid(target) or amount <= 0:
		return
	if global_position.distance_to(source_position) > data.vision_range * 1.5:
		return
	noise_target = source_position
	patrol_direction = global_position.direction_to(source_position)
	patrol_timer = 2.5
	EventBus.monster_alerted.emit(self, source_position)
	if state_machine.current_state != $StateMachine/Dead and not can_detect_target():
		state_machine.transition_to("Patrol")

func _on_state_changed(previous_state: String, next_state: String) -> void:
	state_changed.emit(previous_state, next_state)
	EventBus.monster_state_changed.emit(self, previous_state, next_state)
