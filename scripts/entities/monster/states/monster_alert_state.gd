class_name MonsterAlertState
extends GameState

@onready var monster: Monster = get_parent().get_parent()

func enter(_data: Dictionary = {}) -> void:
    monster.begin_alert()
    monster.play_animation("walk")

func physics_update(delta: float) -> void:
    if monster.can_detect_target():
        transition_requested.emit("Chase", {})
        return
    if monster.advance_alert(delta):
        transition_requested.emit("Search", {})
