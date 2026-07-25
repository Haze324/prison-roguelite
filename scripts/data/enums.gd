class_name GameEnums
extends RefCounted

enum NoiseLevel { SILENT = 0, WHISPER = 1, LOW = 4, MEDIUM = 9, MEDIUM_HIGH = 17, HIGH = 26, EXTREME = 61, MASSIVE = 91 }
enum Rarity { COMMON = 0, UNCOMMON = 1, RARE = 2, EPIC = 3, LEGENDARY = 4 }
enum BuffType { PIERCE = 0, INCENDIARY = 1, TWIN_SHOT = 2, SILENCED = 3, EXPLOSIVE = 4, RICOCHET = 5, ROLL_RESET = 6, VAMPIRIC = 7 }
enum AttackType { MELEE_LIGHT = 0, MELEE_HEAVY = 1, PROJECTILE = 3, SPRAY = 4, CHARGE = 6, SELF_AOE = 9, TARGETED_AOE = 10, PERSISTENT_ZONE = 11 }
enum MonsterTier { GRUNT = 0, ELITE = 1, MINI_BOSS = 2, BOSS = 3 }
enum ReloadMode { MAGAZINE = 0, SINGLE = 1, NONE = 2 }
enum WeaponType { PISTOL = 0, SHOTGUN = 1, MELEE = 2, RIFLE = 3 }
enum ThrowableType { FLARE = 0, SMOKE = 1, GRENADE = 2, MINE = 3 }
enum ConsumableType { AMMO = 0, THROWABLE = 1, HEALING = 2, RESOURCE = 3 }
