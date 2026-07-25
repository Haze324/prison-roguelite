class_name MonsterSearchState
extends GameState

@onready var monster: Monster = get_parent().get_parent()

func enter(_data: Dictionary = {}) -> void:
    monster.begin_search()
    monster.play_animation("walk")

func physics_update(delta: float) -> void:
    if monster.can_detect_target():
        transition_requested.emit("Chase", {})
        return
    if monster.advance_search(delta):
        transition_requested.emit("Patrol", {})
