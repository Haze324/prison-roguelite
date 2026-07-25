class_name MonsterChaseState
extends GameState

@onready var monster: Monster = get_parent().get_parent()

func enter(_data: Dictionary = {}) -> void:
	monster.play_animation("walk")
	EventBus.monster_alerted.emit(monster, monster.target.global_position if monster.target else monster.global_position)

func physics_update(_delta: float) -> void:
	if not monster.can_detect_target():
		transition_requested.emit("Idle", {})
		return
	if monster.is_target_in_attack_range():
		transition_requested.emit("Attack", {})
		return
	monster.chase_target()

