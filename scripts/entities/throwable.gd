class_name Throwable
extends Node2D

var throwable_type: int = GameEnums.ThrowableType.FLARE
var source: Node2D
var velocity: Vector2 = Vector2.ZERO
var fuse_remaining: float = 0.0
var active_remaining: float = 0.0
var flight_remaining: float = 0.0
var blast_damage: float = 0.0
var blast_radius: float = 60.0
var trigger_noise: int = 0
var bounces_remaining: int = 2
var charge_ratio: float = 1.0
var _detonate_on_impact: bool = false
var _landed: bool = false
var triggered: bool = false

func setup(kind: int, start_position: Vector2, owner_node: Node2D, throw_direction: Vector2 = Vector2.RIGHT, throw_charge: float = 1.0) -> void:
    throwable_type = kind
    global_position = start_position
    source = owner_node
    charge_ratio = clampf(throw_charge, 0.2, 1.0)
    velocity = throw_direction.normalized() * lerpf(300.0, 720.0, charge_ratio)
    flight_remaining = lerpf(0.45, 1.0, charge_ratio)
    bounces_remaining = 2
    _landed = false
    triggered = false
    match throwable_type:
        GameEnums.ThrowableType.FLARE:
            fuse_remaining = 0.0
            active_remaining = 6.0
            trigger_noise = 5
        GameEnums.ThrowableType.SMOKE:
            fuse_remaining = 0.0
            active_remaining = 4.0
            trigger_noise = 3
        GameEnums.ThrowableType.GRENADE:
            fuse_remaining = 0.8
            blast_damage = 60.0
            blast_radius = 80.0
            trigger_noise = 80
            _detonate_on_impact = true
        GameEnums.ThrowableType.MINE:
            fuse_remaining = 0.0
            active_remaining = 12.0
            blast_damage = 80.0
            blast_radius = 60.0
            trigger_noise = 40
            _detonate_on_impact = true
    queue_redraw()

func _physics_process(delta: float) -> void:
    if triggered:
        return
    if not _landed:
        _advance_flight(delta)
        if triggered:
            return
    if throwable_type == GameEnums.ThrowableType.MINE:
        active_remaining -= delta
        for node in get_tree().get_nodes_in_group("monsters"):
            var monster: Monster = node as Monster
            if monster != null and monster.global_position.distance_to(global_position) <= 150.0:
                _explode()
                return
        if active_remaining <= 0.0:
            queue_free()
        return
    if fuse_remaining > 0.0:
        fuse_remaining -= delta
        if fuse_remaining <= 0.0:
            _explode()
        return
    active_remaining -= delta
    if active_remaining <= 0.0:
        EventBus.noise_emitted.emit(trigger_noise, global_position, source)
        queue_free()

func _advance_flight(delta: float) -> void:
    flight_remaining = maxf(flight_remaining - delta, 0.0)
    if flight_remaining <= 0.0:
        _land(global_position)
        return
    var next_position: Vector2 = global_position + velocity * delta
    var query: PhysicsRayQueryParameters2D = PhysicsRayQueryParameters2D.create(global_position, next_position)
    query.collision_mask = 1
    var excluded: Array[RID] = []
    if source is CollisionObject2D:
        excluded.append((source as CollisionObject2D).get_rid())
    query.exclude = excluded
    var hit: Dictionary = get_world_2d().direct_space_state.intersect_ray(query)
    if hit.is_empty():
        global_position = next_position
        queue_redraw()
        return
    var hit_position: Vector2 = hit.get("position", global_position)
    var collider: Node = hit.get("collider") as Node
    if _is_monster(collider):
        if _detonate_on_impact:
            global_position = hit_position
            _explode()
        else:
            _land(hit_position)
        return
    if _is_wall(collider):
        var normal: Vector2 = hit.get("normal", Vector2.ZERO)
        bounces_remaining -= 1
        if bounces_remaining <= 0 or normal == Vector2.ZERO:
            _land(hit_position + normal * 3.0)
            return
        global_position = hit_position + normal * 3.0
        velocity = velocity.bounce(normal) * 0.68
        queue_redraw()
        return
    _land(hit_position)

func _land(land_position: Vector2) -> void:
    global_position = land_position
    velocity = Vector2.ZERO
    _landed = true
    queue_redraw()

func _is_monster(node: Node) -> bool:
    return node != null and node.is_in_group("monsters")

func _is_wall(node: Node) -> bool:
    return node != null and (node.is_in_group("实体墙") or node is Wall)

func _explode() -> void:
    if triggered:
        return
    triggered = true
    for node in get_tree().get_nodes_in_group("monsters"):
        var monster: Monster = node as Monster
        if monster != null and monster.global_position.distance_to(global_position) <= blast_radius:
            monster.take_damage(blast_damage)
    EventBus.noise_emitted.emit(trigger_noise, global_position, source)
    queue_free()

func _draw() -> void:
    var color: Color = Color(0.95, 0.8, 0.3, 1.0)
    var radius: float = 12.0
    match throwable_type:
        GameEnums.ThrowableType.SMOKE:
            color = Color(0.65, 0.7, 0.75, 0.8)
            radius = 28.0
        GameEnums.ThrowableType.GRENADE:
            color = Color(0.95, 0.3, 0.18, 1.0)
        GameEnums.ThrowableType.MINE:
            color = Color(0.75, 0.2, 0.8, 1.0)
    if not _landed and velocity.length_squared() > 0.1:
        draw_line(-velocity.normalized() * 22.0, Vector2.ZERO, Color(color, 0.42), 3.0)
    draw_circle(Vector2.ZERO, radius, Color(color, 0.18))
    draw_circle(Vector2.ZERO, 7.0, color)
    draw_circle(Vector2.ZERO, 3.0, Color.WHITE)
