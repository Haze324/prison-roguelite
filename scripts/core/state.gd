class_name GameState
extends Node

signal transition_requested(next_state: String, data: Dictionary)

func enter(_data: Dictionary = {}) -> void:
	pass

func exit() -> void:
	pass

func physics_update(_delta: float) -> void:
	pass

