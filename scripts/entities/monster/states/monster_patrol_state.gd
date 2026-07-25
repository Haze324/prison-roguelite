class_name MonsterPatrolState
extends GameState

@onready var monster: Monster = get_parent().get_parent()

func enter(_data: Dictionary = {}) -> void:
	monster.begin_patrol()

func physics_update(delta: float) -> void:
	if monster.can_detect_target():
		transition_requested.emit("Chase", {})
		return
	if monster.advance_patrol(delta):
		transition_requested.emit("Idle", {})

