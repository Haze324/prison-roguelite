class_name HazardZone
extends Node2D

var target: Node2D
var hazard_type: int = 1
var radius: float = 92.0
var telegraph_remaining: float = 0.65
var active_remaining: float = 3.0
var active: bool = false

func setup(target_node: Node2D, zone_type: int) -> void:
	target = target_node
	hazard_type = zone_type
	radius = 92.0 if hazard_type == 1 else 70.0
	queue_redraw()

func _process(delta: float) -> void:
	if not active:
		telegraph_remaining -= delta
		if telegraph_remaining <= 0.0:
			active = true
			EventBus.noise_emitted.emit(65, global_position, self)
	else:
		active_remaining -= delta
		if is_instance_valid(target) and target.global_position.distance_to(global_position) <= radius:
			var damage: float = 8.0 if hazard_type == 1 else 12.0
			if target.has_method("take_damage"):
				target.take_damage(damage * delta, self)
		if active_remaining <= 0.0:
			queue_free()
	queue_redraw()

func _draw() -> void:
	var color := Color(0.95, 0.27, 0.2, 0.22) if active else Color(1.0, 0.75, 0.24, 0.18)
	var outline := Color(1.0, 0.26, 0.2, 0.9) if active else Color(1.0, 0.78, 0.25, 0.9)
	draw_circle(Vector2.ZERO, radius, color)
	draw_arc(Vector2.ZERO, radius, 0.0, TAU, 48, outline, 3.0)
