class_name AttackData
extends Resource

@export var attack_name: String = ""
@export var attack_type: int = GameEnums.AttackType.MELEE_LIGHT
@export var damage: float = 10.0
@export var windup: float = 0.3
@export var recovery: float = 0.3
@export var cooldown: float = 1.5
@export var is_parryable: bool = true
@export var attack_range: float = 64.0
@export var aoe_radius: float = 80.0
@export var projectile_count: int = 1
@export var spread: float = 0.0
@export var zone_duration: float = 0.0
