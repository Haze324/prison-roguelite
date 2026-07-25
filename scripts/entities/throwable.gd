class_name Throwable
extends Node2D

var throwable_type: int = GameEnums.ThrowableType.FLARE
var source: Node2D
var fuse_remaining: float = 0.0
var active_remaining: float = 0.0
var blast_damage: float = 0.0
var blast_radius: float = 60.0
var trigger_noise: int = 0
var triggered: bool = false

func setup(kind: int, start_position: Vector2, owner_node: Node2D) -> void:
    throwable_type = kind
    global_position = start_position
    source = owner_node
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
        GameEnums.ThrowableType.MINE:
            active_remaining = 12.0
            blast_damage = 80.0
            blast_radius = 60.0
            trigger_noise = 40
    queue_redraw()

func _physics_process(delta: float) -> void:
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
    var color := Color(0.95, 0.8, 0.3, 1.0)
    var radius := 12.0
    match throwable_type:
        GameEnums.ThrowableType.SMOKE:
            color = Color(0.65, 0.7, 0.75, 0.8)
            radius = 28.0
        GameEnums.ThrowableType.GRENADE:
            color = Color(0.95, 0.3, 0.18, 1.0)
        GameEnums.ThrowableType.MINE:
            color = Color(0.75, 0.2, 0.8, 1.0)
    draw_circle(Vector2.ZERO, radius, Color(color, 0.18))
    draw_circle(Vector2.ZERO, 7.0, color)
    draw_circle(Vector2.ZERO, 3.0, Color.WHITE)
