class_name MonsterChaseState
extends GameState

@onready var monster: Monster = get_parent().get_parent()

func enter(_data: Dictionary = {}) -> void:
	monster.target_lost_remaining = 0.0
	monster.play_animation("walk")
	EventBus.monster_alerted.emit(monster, monster.target.global_position if monster.target else monster.global_position)

func physics_update(delta: float) -> void:
	if monster.can_detect_target():
		monster.target_lost_remaining = 0.0
	else:
		monster.target_lost_remaining += delta
		if monster.data.is_boss:
			monster.advance_boss_wander(delta)
			return
		if monster.target_lost_remaining >= 5.0:
			transition_requested.emit("Search", {})
			return
		monster.velocity = Vector2.ZERO
		monster.play_animation("idle")
		return
	if monster.is_target_in_attack_range():
		transition_requested.emit("Attack", {})
		return
	monster.chase_target()
