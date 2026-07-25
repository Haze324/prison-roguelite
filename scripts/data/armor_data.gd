class_name ArmorData
extends Resource

@export var armor_name: String = "Cloth Vest"
@export_range(0.0, 0.8) var damage_reduction: float = 0.15
@export var max_durability: int = 3
@export var durability: int = 3
@export var noise_modifier: int = 0
@export var special_effect: String = ""

func absorb_damage(amount: float) -> float:
    if durability <= 0:
        return amount
    durability = maxi(durability - 1, 0)
    return amount * (1.0 - damage_reduction)

func repair() -> void:
    durability = max_durability
