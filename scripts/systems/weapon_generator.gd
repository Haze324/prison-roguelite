class_name WeaponGenerator
extends RefCounted

const MVP_BUFFS: Array[int] = [
    GameEnums.BuffType.PIERCE,
    GameEnums.BuffType.INCENDIARY,
    GameEnums.BuffType.TWIN_SHOT,
    GameEnums.BuffType.SILENCED,
    GameEnums.BuffType.EXPLOSIVE,
]

static func generate_random(base: WeaponData, seed_value: int = 0) -> WeaponData:
    var rng: RandomNumberGenerator = RandomNumberGenerator.new()
    rng.seed = seed_value if seed_value != 0 else randi()
    var rarity: int = rng.randi_range(GameEnums.Rarity.UNCOMMON, GameEnums.Rarity.EPIC)
    return generate(base, rarity, rng.randi())

static func generate(base: WeaponData, rarity: int, seed_value: int = 0) -> WeaponData:
    if base == null:
        return null
    var generated: WeaponData = base.duplicate(true) as WeaponData
    if generated == null:
        return null
    var rng: RandomNumberGenerator = RandomNumberGenerator.new()
    rng.seed = seed_value if seed_value != 0 else randi()
    generated.rarity = clampi(rarity, GameEnums.Rarity.COMMON, GameEnums.Rarity.LEGENDARY)
    generated.effects.clear()
    var slot_count: int = 1 if generated.rarity <= GameEnums.Rarity.RARE else 2
    if generated.rarity == GameEnums.Rarity.COMMON:
        slot_count = 0
    var available: Array[int] = MVP_BUFFS.duplicate()
    for _slot in slot_count:
        if available.is_empty():
            break
        var selected_index: int = rng.randi_range(0, available.size() - 1)
        generated.effects.append(available[selected_index])
        available.remove_at(selected_index)
    generated.weapon_name = "%s %s" % [_rarity_name(generated.rarity), base.weapon_name]
    return generated

static func _rarity_name(rarity: int) -> String:
    match rarity:
        GameEnums.Rarity.UNCOMMON:
            return "Fine"
        GameEnums.Rarity.RARE:
            return "Rare"
        GameEnums.Rarity.EPIC:
            return "Epic"
        GameEnums.Rarity.LEGENDARY:
            return "Legendary"
        _:
            return "Common"
