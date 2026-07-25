class_name PlayerDashState
extends GameState

@onready var player: Player = get_parent().get_parent()

func enter(_data: Dictionary = {}) -> void:
	player.begin_dash()
	player.play_body_animation("dash")

func physics_update(delta: float) -> void:
	if player.apply_dash_movement(delta):
		var next_state := "Move" if player.get_move_direction() != Vector2.ZERO else "Idle"
		transition_requested.emit(next_state, {})

