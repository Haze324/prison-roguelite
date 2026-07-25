class_name MonsterIdleState
extends GameState

@onready var monster: Monster = get_parent().get_parent()

func enter(_data: Dictionary = {}) -> void:
	monster.velocity = Vector2.ZERO
	monster.play_animation("idle")

func physics_update(delta: float) -> void:
	monster.tick_patrol_timer(delta)
	if monster.can_detect_target():
		transition_requested.emit("Chase", {})
	elif not monster.data.is_boss and monster.patrol_timer <= 0.0:
		transition_requested.emit("Patrol", {})
