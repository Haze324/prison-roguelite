class_name StateMachine
extends Node

## 通用节点状态机。状态以子节点存在，便于在 Godot 场景树中检查和替换。
@export var initial_state: NodePath

var current_state: GameState
var _states: Dictionary = {}

func _ready() -> void:
	for child in get_children():
		if child is GameState:
			_states[child.name] = child
			child.transition_requested.connect(_on_transition_requested)
	if initial_state != NodePath():
		start()

func start() -> void:
	if current_state != null:
		return
	var state_name: String = String(initial_state).get_file()
	if state_name.is_empty():
		state_name = String(initial_state)
	if _states.has(state_name):
		transition_to(state_name)

func transition_to(state_name: String, data: Dictionary = {}) -> void:
	if not _states.has(state_name) or _states[state_name] == current_state:
		return
	var previous_name: String = ""
	if current_state != null:
		previous_name = String(current_state.name)
	if current_state != null:
		current_state.exit()
	current_state = _states[state_name]
	current_state.enter(data)
	var owner_node: Node = get_parent()
	if owner_node.has_signal("state_changed"):
		owner_node.state_changed.emit(previous_name, state_name)
	EventBus.player_state_changed.emit(previous_name, state_name)

func physics_update(delta: float) -> void:
	if current_state != null:
		current_state.physics_update(delta)

func _on_transition_requested(next_state: String, data: Dictionary) -> void:
	transition_to(next_state, data)
