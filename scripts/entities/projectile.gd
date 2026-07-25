class_name Projectile
extends Node2D

## 轻量级 2D 弹道：用连续射线避免高速子弹穿透目标。
var velocity: Vector2 = Vector2.RIGHT
var damage: float = 1.0
var source: Node2D
var start_position: Vector2
var lifetime: float = 1.5
var max_range: float = 0.0
var distance_traveled: float = 0.0
var tint: Color = Color(1.0, 0.85, 0.35, 1.0)
var weapon_effects: Array[int] = []
var hit_targets: Array[Node2D] = []

func setup(start: Vector2, direction: Vector2, speed: float, hit_damage: float, owner_node: Node2D, effects: Array[int] = [], weapon_range: float = 0.0) -> void:
	start_position = start
	global_position = start
	velocity = direction.normalized() * speed
	damage = hit_damage
	source = owner_node
	weapon_effects = effects
	max_range = weapon_range
	distance_traveled = 0.0
	hit_targets.clear()
	if weapon_effects.has(GameEnums.BuffType.INCENDIARY):
		tint = Color(1.0, 0.32, 0.12, 1.0)
	rotation = velocity.angle()

func _ready() -> void:
	queue_redraw()

func _physics_process(delta: float) -> void:
	lifetime -= delta
	if lifetime <= 0.0:
		queue_free()
		return
	var next_position: Vector2 = global_position + velocity * delta
	var step_distance: float = global_position.distance_to(next_position)
	var reached_range: bool = false
	if max_range > 0.0 and distance_traveled + step_distance > max_range:
		var remaining_range: float = max_range - distance_traveled
		if remaining_range <= 0.0:
			queue_free()
			return
		next_position = global_position + velocity.normalized() * remaining_range
		step_distance = remaining_range
		reached_range = true
	var query: PhysicsRayQueryParameters2D = PhysicsRayQueryParameters2D.create(global_position, next_position)
	query.collision_mask = 1
	var excluded: Array[RID] = []
	if source is CollisionObject2D:
		excluded.append((source as CollisionObject2D).get_rid())
	for hit_target in hit_targets:
		if is_instance_valid(hit_target) and hit_target is CollisionObject2D:
			excluded.append((hit_target as CollisionObject2D).get_rid())
	query.exclude = excluded
	var hit: Dictionary = get_world_2d().direct_space_state.intersect_ray(query)
	if not hit.is_empty():
		var collider: Object = hit.get("collider") as Object
		if collider != null and collider.has_method("take_damage"):
			var hit_position: Vector2 = Vector2(hit.get("position", global_position))
			var hit_distance: float = distance_traveled + global_position.distance_to(hit_position)
			var falloff: float = 1.0
			if max_range > 0.0 and hit_distance > max_range:
				falloff = maxf(pow(max_range / maxf(hit_distance, 1.0), 2.0), 0.1)
			var final_damage: float = damage * falloff
			collider.take_damage(final_damage)
			if weapon_effects.has(GameEnums.BuffType.INCENDIARY) and collider.has_method("apply_burn"):
				collider.apply_burn(final_damage * 0.3, 2.0)
			if weapon_effects.has(GameEnums.BuffType.EXPLOSIVE):
				for node in get_tree().get_nodes_in_group("monsters"):
					var monster: Node2D = node as Node2D
					if monster != null and monster != collider and monster.global_position.distance_to(global_position) <= 80.0 and monster.has_method("take_damage"):
						monster.take_damage(final_damage * 0.5)
				EventBus.noise_emitted.emit(15, global_position, source)
			if weapon_effects.has(GameEnums.BuffType.PIERCE) and collider is Node2D and not hit_targets.has(collider as Node2D):
				hit_targets.append(collider as Node2D)
				global_position = hit_position + velocity.normalized() * 2.0
				distance_traveled = hit_distance
				return
		queue_free()
		return
	global_position = next_position
	distance_traveled += step_distance
	if reached_range:
		queue_free()

func _draw() -> void:
	draw_line(Vector2(-7.0, 0.0), Vector2(4.0, 0.0), tint, 3.0, true)
	draw_circle(Vector2(4.0, 0.0), 2.0, Color.WHITE)
