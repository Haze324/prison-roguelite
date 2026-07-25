class_name DamageSystem
extends RefCounted

static func rarity_multiplier(rarity: int) -> float:
    match rarity:
        GameEnums.Rarity.UNCOMMON:
            return 1.2
        GameEnums.Rarity.RARE:
            return 1.4
        GameEnums.Rarity.EPIC:
            return 1.7
        GameEnums.Rarity.LEGENDARY:
            return 2.0
        _:
            return 1.0

static func calculate_weapon_damage(weapon: WeaponData, distance: float, aiming: bool, target_armor: float = 0.0) -> float:
    var damage: float = weapon.damage * rarity_multiplier(weapon.rarity)
    if distance > weapon.range:
        damage *= maxf(pow(weapon.range / maxf(distance, 1.0), 2.0), 0.1)
    if aiming and not weapon.is_melee:
        damage *= 1.3
    damage *= 1.0 - clampf(target_armor, 0.0, 0.8)
    return damage
