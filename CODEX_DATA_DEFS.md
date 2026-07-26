# Codex 数据定义 — 全局枚举 + Resource 类完整字段

---

## 全局枚举

文件：`scripts/data/enums.gd`

```gdscript
class_name GameEnums

# --- 噪声等级 ---
enum NoiseLevel {
    SILENT = 0,       # 零：站立/被击中/完美格挡/喝血瓶
    WHISPER = 1,      # 微：1-3，走路/切换武器/手电筒
    LOW = 4,          # 低：4-8，跑步/翻滚
    MEDIUM = 9,       # 中：9-16，换弹
    MEDIUM_HIGH = 17, # 中高：17-25，近战攻击
    HIGH = 26,        # 高：26-60，枪械开火
    EXTREME = 61,     # 极高：61-90，爆炸物/破门
    MASSIVE = 91      # 特大：91+，修复电源
}

# --- 稀有度 ---
enum Rarity {
    COMMON = 0,       # 普通（白）×1.0，0 slot
    UNCOMMON = 1,     # 精良（绿）×1.2，1 slot
    RARE = 2,         # 稀有（蓝）×1.4，1 slot
    EPIC = 3,         # 史诗（紫）×1.7，2 slots
    LEGENDARY = 4     # 传说（金）×2.0，2 slots + 机制独占
}

# --- Buff 类型（8个） ---
enum BuffType {
    PIERCE = 0,       # 穿透（精良）
    INCENDIARY = 1,   # 燃烧（精良）
    TWIN_SHOT = 2,    # 双发（稀有）
    SILENCED = 3,     # 抑制（稀有）
    EXPLOSIVE = 4,    # 爆炸（史诗）
    RICOCHET = 5,     # 弹射（稀有，非MVP）
    ROLL_RESET = 6,   # 暗影步（传说，非MVP）
    VAMPIRIC = 7      # 吸血（传说，非MVP）
}

# --- 攻击类型 ---
enum AttackType {
    MELEE_LIGHT = 0, MELEE_HEAVY = 1, MELEE_COMBO = 2,
    PROJECTILE = 3, SPRAY = 4, TRACKING = 5,
    CHARGE = 6, LEAP = 7, BURROW = 8,
    SELF_AOE = 9, TARGETED_AOE = 10, PERSISTENT_ZONE = 11,
    SLOW = 12, BLIND = 13, BIND = 14, NOISE_INTERFERENCE = 15
}

# --- 怪物层级 ---
enum MonsterTier { GRUNT = 0, ELITE = 1, MINI_BOSS = 2, BOSS = 3 }

# --- 怪物状态 ---
enum MonsterState { IDLE = 0, PATROL = 1, ALERT = 2, COMBAT = 3, SEARCH = 4, DEAD = 5 }

# --- 换弹模式 ---
enum ReloadMode { MAGAZINE = 0, SINGLE = 1, NONE = 2 }

# --- 武器类型 ---
enum WeaponType { PISTOL = 0, SHOTGUN = 1, MELEE = 2, RIFLE = 3 }

# --- 防具部位 ---
enum ArmorSlot { HEAD = 0, HANDS = 1, BODY = 2 }

# --- 投掷物类型 ---
enum ThrowableType { FLARE = 0, SMOKE = 1, GRENADE = 2, MINE = 3 }

# --- 关卡主题 ---
enum LevelTheme { BIOHAZARD = 0, PLANT = 1 }

# --- 噪声区间 ---
enum NoiseZone { GREEN = 0, YELLOW = 1, RED = 2 }
```

---

## 背包与装备数据模型（2026-07-26 决策）

装备栏固定使用以下槽位 ID：

```text
armor_head       # 头部防具
armor_hands      # 手部防具
armor_body       # 身体防具
weapon_1         # 武器 1
weapon_2         # 武器 2
healing          # 回复血瓶，独立回复槽
consumable       # 消耗品，最多一种类型
throwable_1      # 投掷物 1
throwable_2      # 投掷物 2
```

背包栏使用可配置容量的 `ItemStack` 网格：

```text
ItemStack {
    item_data: WeaponData | ArmorData | ConsumableData
    quantity: int
    source_slot: String
}
```

- 武器、防具数量固定为 1，不可堆叠。
- 回复血瓶与消耗品分属不同装备槽和使用按键；回复血瓶使用 `Q`，消耗品使用 `F`。
- 回复血瓶、消耗品和投掷物分别按自身类型数据堆叠，不得跨类别合并。
- 装备栏与背包栏必须使用同一套物品数据引用，拖拽只改变位置和装备状态，不复制数据。
- 背包容量、初始物品和最大堆叠数由 `.tres` 或背包配置资源管理。

---

## WeaponData Resource

文件：`scripts/data/weapon_data.gd`

```gdscript
class_name WeaponData
extends Resource

## 武器名称
@export var weapon_name: String = ""

## 武器类型
@export var weapon_type: int = GameEnums.WeaponType.PISTOL

## 武器图标 — 点一下即可换图
@export var icon: Texture2D

## 单发/单颗弹丸伤害（稀有度乘数在管线中另外应用）
@export var damage: float = 15.0

## 射击间隔（秒），越小越快
@export var fire_rate: float = 0.4

## 弹匣容量，0 = 无需换弹（近战武器）
@export var mag_size: int = 12

## 换弹时间（秒），0 = 无需换弹
@export var reload_time: float = 1.5

## 换弹模式：0=弹匣式 1=逐发装填 2=无
@export var reload_mode: int = GameEnums.ReloadMode.MAGAZINE

## 有效射程（像素），超出后伤害平方衰减（保底10%）。近战武器 = hitbox 范围
@export var range: float = 400.0

## 每次开火产生的噪声值
@export_range(0, 100) var noise: int = 30

## 弹丸数，默认1，霰弹枪=5
@export var pellets: int = 1

## 散布角（度），霰弹25°，手枪2°
@export var spread: float = 2.0

## 稀有度
@export var rarity: int = GameEnums.Rarity.COMMON

## 特殊效果列表（BuffType 枚举数组）
@export var effects: Array[int] = []

## 近战碰撞体形状："arc"扇形 / "rect"矩形（仅近战武器使用）
@export var hitbox_shape: String = "arc"

## 近战扇形角度（仅近战武器使用）
@export var hitbox_angle: float = 120.0
```

---

## NoiseConfig Resource

文件：`scripts/data/noise_config.gd`

```gdscript
class_name NoiseConfig
extends Resource

## 临时噪声每秒衰减量
@export var temp_decay_per_second: float = 8.0

## 残留转换率（每次临时噪声产生时，该比例的数值同步加入残留）
@export_range(0.0, 1.0) var residual_conversion_rate: float = 0.15

## 残留噪声每10秒衰减量
@export var residual_decay_per_10s: float = 2.0

## Boss苏醒阈值：临时+残留≥此值即苏醒
@export var boss_threshold: float = 200.0

## 绿色区上限
@export var zone_green_ceiling: float = 50.0

## 黄色区上限
@export var zone_yellow_ceiling: float = 120.0

## 红色区上限
@export var zone_red_ceiling: float = 199.0
```

---

## MonsterData Resource

文件：`scripts/data/monster_data.gd`

```gdscript
class_name MonsterData
extends Resource

## 怪物名称
@export var monster_name: String = ""

## 层级
@export var tier: int = GameEnums.MonsterTier.GRUNT

## 所属关卡
@export var level_theme: int = GameEnums.LevelTheme.BIOHAZARD

## 生命值
@export var hp: float = 30.0

## 移动速度（相对玩家走路速度的倍数）
@export var move_speed: float = 0.8

## 视觉感知距离（像素），0=无视觉
@export var vision_range: float = 200.0

## 听觉感知：触发Alert的最低噪声等级
@export var hearing_threshold: int = GameEnums.NoiseLevel.MEDIUM

## 听觉感知距离（像素）
@export var hearing_range: float = 400.0

## 天然护甲减伤比例（0.0-1.0），Boss可用
@export_range(0.0, 1.0) var natural_armor: float = 0.0

## Alert暂停观察时长（秒），精英更短，Boss不使用
@export var alert_pause_duration: float = 0.5

## Search搜索时长（秒）
@export var search_duration: float = 8.0

## 是否有walk动画（Boss=false）
@export var has_walk: bool = true

## 攻击技能列表
@export var attacks: Array[AttackData] = []

## 怪物外观 — 点一下换图（S0阶段可空着）
@export var sprite: Texture2D
```

---

## AttackData Resource

文件：`scripts/data/attack_data.gd`

```gdscript
class_name AttackData
extends Resource

## 攻击名称
@export var attack_name: String = ""

## 攻击类型
@export var attack_type: int = GameEnums.AttackType.MELEE_LIGHT

## 伤害值
@export var damage: float = 10.0

## 前摇时间（秒）
@export var windup: float = 0.3

## 收招时间（秒）
@export var recovery: float = 0.3

## 冷却时间（秒）
@export var cooldown: float = 1.5

## 是否可被格挡
@export var is_parryable: bool = true

## 预警类型：0=动作前摇 1=地面圈 2=声音 3=弹道可见 4=环境线索
@export var warning_type: int = 0

## 攻击范围（像素），近战/冲锋/喷洒使用
@export var attack_range: float = 64.0

## AOE半径（像素），AOE类攻击使用
@export var aoe_radius: float = 80.0

## 撞墙后是否眩晕
@export var stop_on_wall: bool = false

## 撞墙眩晕时长（秒），冲锋类使用
@export var wall_stun_duration: float = 2.0

## 弹丸数，弹道类使用
@export var projectile_count: int = 1

## 散布角（度），弹道类使用
@export var spread: float = 0.0

## 持续区域时长（秒），持续区域类使用
@export var zone_duration: float = 0.0

## Boss阶段限制（0=全阶段 1=P1 2=P2 3=P3）
@export var boss_phase: int = 0
```

---

## ArmorData Resource

文件：`scripts/data/armor_data.gd`

```gdscript
class_name ArmorData
extends Resource

## 防具名称
@export var armor_name: String = ""

## 装备部位：0=头 1=手 2=身体
@export var slot: int = GameEnums.ArmorSlot.BODY

## 减伤比例（0.0-1.0），命中该部位时 damage × (1-DR)
@export_range(0.0, 1.0) var damage_reduction: float = 0.3

## 耐久度上限
@export var max_durability: int = 3

## 特殊效果描述
@export var special_effect: String = ""
```

---

## ConsumableData Resource

文件：`scripts/data/consumable_data.gd`

```gdscript
class_name ConsumableData
extends Resource

## 消耗品名称
@export var item_name: String = ""

## 类型：0=弹药箱 1=投掷物 2=肾上腺素 3=其他 4=回复血瓶
@export var item_type: int = 0

## 使用通道：4=healing 槽并由 Q 使用；其余非治疗物品进入 consumable 槽并由 F 使用

## 携带上限
@export var max_carry: int = 2

## 使用时产生的噪声值
@export var noise_on_use: int = 0

## 物品图标 — 点一下换图
@export var icon: Texture2D

## 使用音效 — 拖音频文件到这里
@export var use_sound: AudioStream

# --- 仅投掷物需要以下字段 ---

## 投掷物子类型（0=信号弹 1=烟雾弹 2=手榴弹 3=噪声地雷）
@export var throwable_subtype: int = 0

## 触发后噪声值（仅地雷）
@export var noise_on_trigger: int = 0

## 触发半径（像素，仅地雷）
@export var trigger_radius: float = 150.0

## 爆炸半径（像素，手榴弹/地雷）
@export var blast_radius: float = 60.0

## 爆炸伤害
@export var blast_damage: float = 0.0
```

---

## BuffData Resource

文件：`scripts/data/buff_data.gd`

```gdscript
class_name BuffData
extends Resource

## Buff名称
@export var buff_name: String = ""

## Buff类型
@export var buff_type: int = GameEnums.BuffType.PIERCE

## 所需最低稀有度
@export var required_rarity: int = GameEnums.Rarity.UNCOMMON

## 是否MVP阶段实现
@export var is_mvp: bool = true
```
