class_name MonsterAttackState
extends GameState

@onready var monster: Monster = get_parent().get_parent()

func enter(_data: Dictionary = {}) -> void:
	monster.begin_attack()

func physics_update(delta: float) -> void:
	if monster.advance_attack(delta):
		transition_requested.emit("Chase", {})

