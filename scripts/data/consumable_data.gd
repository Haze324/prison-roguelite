class_name ConsumableData
extends Resource

@export var item_name: String = "Medkit"
@export var item_id: String = "medkit"
@export var item_type: int = GameEnums.ConsumableType.HEALING
@export var max_carry: int = 2
@export var use_noise: int = 0
@export var heal_amount: float = 35.0
@export var throwable_type: int = GameEnums.ThrowableType.FLARE
@export var trigger_noise: int = 0
@export var blast_damage: float = 0.0
@export var blast_radius: float = 60.0
@export var effect_duration: float = 3.0
