class_name Projectile
extends Node2D

## 轻量级 2D 弹道：用连续射线避免高速子弹穿透目标。
var velocity: Vector2 = Vector2.RIGHT
var damage: float = 1.0
var source: Node2D
var lifetime: float = 1.5
var tint: Color = Color(1.0, 0.85, 0.35, 1.0)

func setup(start_position: Vector2, direction: Vector2, speed: float, hit_damage: float, owner_node: Node2D) -> void:
	global_position = start_position
	velocity = direction.normalized() * speed
	damage = hit_damage
	source = owner_node
	rotation = velocity.angle()

func _ready() -> void:
	queue_redraw()

func _physics_process(delta: float) -> void:
	lifetime -= delta
	if lifetime <= 0.0:
		queue_free()
		return
	var next_position: Vector2 = global_position + velocity * delta
	var query: PhysicsRayQueryParameters2D = PhysicsRayQueryParameters2D.create(global_position, next_position)
	query.collision_mask = 1
	var excluded: Array[RID] = []
	if source is CollisionObject2D:
		excluded.append((source as CollisionObject2D).get_rid())
	query.exclude = excluded
	var hit: Dictionary = get_world_2d().direct_space_state.intersect_ray(query)
	if not hit.is_empty():
		var collider: Object = hit.get("collider") as Object
		if collider != null and collider.has_method("take_damage"):
			collider.take_damage(damage)
		queue_free()
		return
	global_position = next_position

func _draw() -> void:
	draw_line(Vector2(-7.0, 0.0), Vector2(4.0, 0.0), tint, 3.0, true)
	draw_circle(Vector2(4.0, 0.0), 2.0, Color.WHITE)
