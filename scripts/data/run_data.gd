class_name RunData
extends Resource

@export var level_index: int = 1
@export var map_seed: int = 0
@export var temporary_noise: float = 0.0
@export var residual_noise: float = 0.0
@export var power_nodes_fixed: int = 0
@export var total_power_nodes: int = 3
@export var coins: int = 0
@export var skill_points: int = 0
@export var boss_awakened: bool = false
@export var boss_defeated: bool = false
@export var escaped: bool = false

func reset_run(new_seed: int = 0) -> void:
    level_index = 1
    map_seed = new_seed if new_seed != 0 else randi()
    temporary_noise = 0.0
    residual_noise = 0.0
    power_nodes_fixed = 0
    boss_awakened = false
    boss_defeated = false
    escaped = false
