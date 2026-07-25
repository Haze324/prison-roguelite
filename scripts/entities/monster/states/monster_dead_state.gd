class_name MonsterDeadState
extends GameState

@onready var monster: Monster = get_parent().get_parent()

func enter(_data: Dictionary = {}) -> void:
	monster.velocity = Vector2.ZERO
	monster.play_animation("death")
	EventBus.monster_killed.emit(monster)

func physics_update(delta: float) -> void:
	if monster.advance_death(delta):
		monster.queue_free()

