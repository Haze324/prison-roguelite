class_name PlayerIdleState
extends GameState

@onready var player: Player = get_parent().get_parent()

func enter(_data: Dictionary = {}) -> void:
	player.play_body_animation("idle")

func physics_update(delta: float) -> void:
	if player.consume_dash_request():
		transition_requested.emit("Dash", {})
		return
	var direction := player.get_move_direction()
	if direction != Vector2.ZERO:
		transition_requested.emit("Move", {})
		return
	player.apply_normal_movement(Vector2.ZERO, delta)
	player.update_combat_facing()

