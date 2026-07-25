# Codex 开发交接文档 — Prison Roguelite

> **阅读对象**：Codex（执行层程序员）  
> **架构师**：Claude Code（接口定义 + 跨系统集成 + Git/GitHub）  
> **项目仓库**：https://github.com/Haze324/prison-roguelite  

---

## 0. 项目一句话

2D 俯视角 Roguelite 恐怖战术射击游戏。核心钩子：「噪声即资源」——开枪能杀敌但引来怪物，沉默安全但越来越穷。噪声累积到阈值惊醒 Boss。

---

## 1. 开发工具和环境

| 工具 | 版本 | 用途 |
|------|------|------|
| **Godot Engine** | 4.4+ (.NET 不启用，纯 GDScript) | 游戏引擎 |
| **Godot MCP** | 已配置 | Claude Code 通过 MCP 操作 Godot 编辑器 |
| **Git** | 最新 | 版本控制 |
| **GitHub** | 仓库 `Haze324/prison-roguelite` | 远程仓库 |

### 推荐 Godot 编辑器插件（非必须，但有用）

- **LimboAI**（Asset Library）：行为树 + 状态机可视化编辑器（MIT）
- **Expresso Inventory**（Asset Library）：背包系统插件（MIT）
- **NZ_projectiles**（GitHub）：弹道系统插件（MIT）

> 这三个是 GDExtension 或 addon，Claude Code 负责引入和集成。Codex 不需要处理这些，专注写 GDScript。

---

## 2. 核心编码标准

### 2.1 数值管理：全部 .tres

**绝不硬编码数值。** 所有武器伤害、怪物 HP、噪声值、衰减速率等必须定义在 `.tres` Resource 文件中。

```
规则：逻辑代码只读 .tres 字段，不自带任何数值常数。
例外：数学常数（如 PI）、引擎常量（如 TAU）可以使用。
```

**调参方式**：在 Godot 编辑器中打开 `.tres` → Inspector 面板 → 改参数 → Ctrl+S → 立刻生效。零编译、零重启、不改代码。

### 2.2 中文注释：所有 @export 字段

**每一个 `@export` 变量都必须有 `##` 中文注释。** 这个注释会在 Godot Inspector 中显示为悬浮提示——策划/美术不需要打开代码就能理解每个字段的含义。

```gdscript
# ✅ 正确
## 单发基础伤害（稀有度乘数会在此基础上应用）
@export var damage: float = 15.0

## 弹匣容量，设为 0 表示不需要换弹（近战武器）
@export var mag_size: int = 12

# ❌ 错误——没有注释
@export var damage: float = 15.0
```

### 2.3 美术资源：全可视化替换

所有图片/音效/粒子等资源通过 `@export` 暴露，在 Godot Inspector 中拖拽替换：

```gdscript
## 武器图标 — 在 Inspector 中点一下即可替换图片
@export var icon: Texture2D

## 开枪音效 — 拖 .wav/.mp3 文件到此处
@export var fire_sound: AudioStream

## 子弹场景 — 拖 .tscn 预制体到此处
@export var bullet_scene: PackedScene
```

### 2.4 文件命名

| 类型 | 命名规则 | 示例 |
|------|------|------|
| GDScript 类 | snake_case | `weapon_data.gd`, `noise_system.gd` |
| .tres 资源 | type_rarity_effect（武器）、type_level（怪物）、type（消耗品） | `pistol_common.tres`, `shotgun_epic.tres`, `crowbar.tres`, `prisoner_var_1.tres`, `ammo_box.tres` |
| 场景 | snake_case | `player.tscn`, `main_menu.tscn`, `hud.tscn` |
| 图片/音效 | snake_case | `prisoner_var_idle.png`, `pistol_fire.wav` |
| 目录 | snake_case | `scripts/data/`, `resources/weapons/` |

### 2.5 GDScript 风格

- `class_name` 声明在每个 Resource/Singleton 文件顶部
- `class_name` 和文件名一致（如 `weapon_data.gd` → `class_name WeaponData`）
- 只暴露必要的公共方法，内部逻辑用 `func _` 前缀或 `static func`
- 信号通过 `EventBus` Autoload 全局通信，不直接跨节点引用
- 不要 `print()` 调试——用 `push_warning()` 或 `assert()`

---

## 3. 目录结构

```
prison-roguelite/
├── project.godot                     # Godot 项目配置 + Autoload + 输入映射
├── .gitignore
├── game-design-decisions.md          # 完整 GDD（设计真相源）
│
├── scripts/
│   ├── data/                         # Resource 类定义
│   │   ├── enums.gd                  # 全局枚举
│   │   ├── weapon_data.gd            # WeaponData Resource
│   │   ├── monster_data.gd           # MonsterData Resource
│   │   ├── armor_data.gd             # ArmorData Resource
│   │   ├── consumable_data.gd        # ConsumableData Resource
│   │   ├── buff_data.gd              # BuffData Resource
│   │   └── noise_config.gd           # NoiseConfig Resource
│   │
│   ├── core/                         # 核心系统
│   │   ├── event_bus.gd              # 全局信号总线 (Autoload)
│   │   └── game_data.gd              # 跨场景玩家状态 (Autoload)
│   │
│   ├── systems/                      # 系统逻辑
│   │   ├── noise_system.gd           # 噪声管理
│   │   ├── damage_pipeline.gd        # 9步伤害管线
│   │   ├── monster_fsm.gd            # 怪物状态机
│   │   ├── weapon_system.gd          # 射击/近战/换弹
│   │   ├── aim_parry_system.gd       # 右键瞄准/格挡
│   │   ├── inventory_system.gd       # 背包管理
│   │   ├── map_generator.gd          # 程序地图生成
│   │   └── save_system.gd            # 存档管理
│   │
│   └── entities/                     # 实体脚本
│       ├── player.gd                 # 玩家控制器
│       ├── monster_base.gd           # 怪物基类
│       └── projectile_base.gd        # 子弹/弹道基类
│
├── resources/                        # .tres 数值文件
│   ├── weapons/                      # 武器数据
│   │   ├── weapon_data.gd           # （同 scripts/data/ 下的那个）
│   │   ├── pistol_common.tres        # 手枪·普通
│   │   ├── shotgun_common.tres       # 霰弹枪·普通
│   │   └── crowbar.tres              # 撬棍
│   ├── monsters/                     # 怪物数据
│   ├── consumables/                  # 消耗品数据
│   ├── noise_config.tres             # 噪声配置（衰减/阈值/三区边界）
│   └── buff_config.tres              # Buff 配置
│
├── scenes/                           # 场景文件
│   ├── core/                         # 核心场景
│   │   ├── main.tscn                 # 启动场景
│   │   ├── world.tscn                # 游戏世界容器
│   │   └── base.tscn                 # 基地（牢房）
│   ├── entities/                     # 实体场景
│   │   ├── player.tscn
│   │   └── monsters/
│   ├── ui/                           # UI 场景
│   │   ├── hud.tscn
│   │   ├── backpack.tscn
│   │   └── main_menu.tscn
│   └── levels/                       # 关卡模板
│
├── assets/                           # 美术/音频
│   ├── sprites/                      # S0 阶段：Godot 原生几何图形拼的角色
│   ├── audio/                        # 音效（.wav/.mp3）
│   └── fonts/
│
└── addons/                           # 第三方插件（Claude Code 管理）
    ├── limboai/
    ├── inventory_system/
    └── nz_projectiles/
```

---

## 4. Claude Code ↔ Codex 分工

### Claude Code（架构师 + Git 管理员）

| 职责 | 具体内容 |
|------|------|
| 设计讨论 | 所有 GDD 修改、系统新增/修改 |
| 接口定义 | 函数签名、信号列表、参数格式——写好了交给 Codex |
| 项目配置 | `project.godot`、Autoload 注册、输入映射、GDExtension 集成 |
| 跨系统集成 | 把 Codex 写的各模块串联起来 |
| Git 管理 | `git add/commit/push`、submodule 管理 |
| 审查 | 检查 Codex 写的代码是否符合接口约定 |

### Codex（执行层程序员）

| 职责 | 具体内容 |
|------|------|
| Resource 类 | 按接口定义写 `*_data.gd` 文件，每个 `@export` 必须有 `##` 中文注释 |
| .tres 文件 | 按数据表创建 `.tres` 并填入数值 |
| 系统逻辑 | 按接口定义实现 `systems/*.gd` |
| 场景搭建 | 拼节点、设属性、创建 2D 场景 |
| AnimationPlayer | 设关键帧动画（idle/walk/attack/death） |
| UI 场景 | 拼 HUD/背包/主菜单的 Control 节点 |
| S0 美术 | 用 Godot 原生矩形/圆形拼怪物外观（6 色色板） |

### 你不负责的事

- Git 任何操作
- 修改 `project.godot`
- 修改 `game-design-decisions.md`
- 决定设计方向

---

## 5. S0 美术标准

### 5.1 色板

**关 1 — 生化实验区（6 色）：**

| 色名 | 十六进制 |
|------|------|
| 暗红 | `#4A1010` |
| 肉粉 | `#C97B7B` |
| 深褐 | `#2C1A0E` |
| 血红 | `#8B0000` |
| 骨白 | `#D4C5B0` |
| 黑 | `#000000` |

**关 2 — 植物实验区（6 色）：**

| 色名 | 十六进制 |
|------|------|
| 腐绿 | `#2D4A1E` |
| 暗紫 | `#3D1A4A` |
| 苔黄 | `#6B7A2E` |
| 绿荧 | `#4AFF3A` |
| 灰褐 | `#4A3D3D` |
| 黑 | `#000000` |

### 5.2 画法

**全部在 Godot 编辑器内完成——用 ColorRect、Sprite2D（单色纹理）、多边形节点拼角色。不用任何外部绘图工具。**

怪物由以下 Godot 原生节点组合成：
- `ColorRect` — 矩形（身体、手臂、腿）
- 圆形纹理/`Sprite2D` + 圆形贴图 — 头、眼睛
- 所有节点放在一个 `Node2D` 根节点下

```
变异囚犯（关 1）节点层级：
  VariantPrisoner (Node2D)
  ├── Body (ColorRect) — 暗红 32×48
  ├── ArmLeft (ColorRect) — 深褐 28×8
  ├── ArmRight (ColorRect) — 暗红 36×12（肿胀利爪，更大）
  ├── Head (Sprite2D + 肉粉圆形纹理 r=10)
  ├── EyeL (ColorRect 红色 2×2)
  ├── EyeR (ColorRect 红色 2×2)
  └── AnimationPlayer — 关键帧动画
```

### 5.3 动画

全部用 `AnimationPlayer` + 关键帧，不需要精灵表（Sprite Sheet）：

| 动画名 | 时长 | 做法 |
|------|:--:|------|
| `idle` | 1.5s | scale 1.0 ↔ 1.03 呼吸，上下微动 |
| `walk` | 0.8s | 左右平移 + 手臂前后摆动 |
| `attack` | 0.5s | 攻击臂 45° 挥出 + 收回 |
| `death` | 1.0s | 整体 scale 压扁 + modulate 变透明 |

### 5.4 可替换性保证

每个怪物/武器的 `@export var sprite: Texture2D` 允许未来直接拖图替换。S0 几何形 → 拖一张像素图 → UI 立即更新，逻辑不动。

---

## 6. 全局枚举（`enums.gd`）

这是整个项目的基础。写在一个文件里，所有其他脚本引用。

```gdscript
# scripts/data/enums.gd
class_name GameEnums
# 不使用 class_name 也可以定义为 const 常量或单独枚举

# --- 噪声等级 ---
enum NoiseLevel {
    SILENT = 0,      # 零：站立/被击中/完美格挡/喝血瓶
    WHISPER = 1,     # 微：1-3，走路/切换武器/手电筒
    LOW = 4,         # 低：4-8，跑步/翻滚
    MEDIUM = 9,      # 中：9-16，换弹
    MEDIUM_HIGH = 17,# 中高：17-25，近战攻击
    HIGH = 26,       # 高：26-60，枪械开火
    EXTREME = 61,    # 极高：61-90，爆炸物/破门
    MASSIVE = 91     # 特大：91+，修复电源
}

# --- 稀有度 ---
enum Rarity {
    COMMON = 0,      # 普通（白）×1.0，0 Buff槽
    UNCOMMON = 1,    # 精良（绿）×1.2，1 Buff槽
    RARE = 2,        # 稀有（蓝）×1.4，1 Buff槽
    EPIC = 3,        # 史诗（紫）×1.7，2 Buff槽
    LEGENDARY = 4    # 传说（金）×2.0，2 Buff槽 + 机制独占
}

# --- Buff 类型 ---
enum BuffType {
    PIERCE = 0,      # 穿透（精良）
    INCENDIARY = 1,  # 燃烧（精良）
    TWIN_SHOT = 2,   # 双发（稀有）
    SILENCED = 3,    # 抑制（稀有）
    EXPLOSIVE = 4,   # 爆炸（史诗）
    RICOCHET = 5,    # 弹射（稀有，非MVP）
    ROLL_RESET = 6,  # 暗影步（传说，非MVP）
    VAMPIRIC = 7     # 吸血（传说，非MVP）
}

# --- 攻击类型 ---
enum AttackType {
    MELEE_LIGHT = 0,
    MELEE_HEAVY = 1,
    MELEE_COMBO = 2,
    PROJECTILE = 3,
    SPRAY = 4,
    TRACKING = 5,
    CHARGE = 6,
    LEAP = 7,
    BURROW = 8,
    SELF_AOE = 9,
    TARGETED_AOE = 10,
    PERSISTENT_ZONE = 11,
    SLOW = 12,
    BLIND = 13,
    BIND = 14,
    NOISE_INTERFERENCE = 15
}

# --- 怪物层级 ---
enum MonsterTier {
    GRUNT = 0,       # 杂兵
    ELITE = 1,       # 精英
    MINI_BOSS = 2,   # 小 Boss
    BOSS = 3         # 大 Boss（未来）
}

# --- 怪物状态 ---
enum MonsterState {
    IDLE = 0,
    PATROL = 1,
    ALERT = 2,
    COMBAT = 3,
    SEARCH = 4,
    DEAD = 5
}

# --- 换弹模式 ---
enum ReloadMode {
    MAGAZINE = 0,    # 弹匣式（一次换满）
    SINGLE = 1,      # 逐发装填（霰弹枪）
    NONE = 2         # 无需换弹（近战武器）
}

# --- 武器类型 ---
enum WeaponType {
    PISTOL = 0,
    SHOTGUN = 1,
    MELEE = 2,
    RIFLE = 3       # 未来版本
}

# --- 投掷物类型 ---
enum ThrowableType {
    FLARE = 0,       # 信号弹（照明）
    SMOKE = 1,       # 烟雾弹（遮蔽视线）
    GRENADE = 2,     # 手榴弹（范围杀伤）
    MINE = 3         # 噪声地雷（诱敌陷阱，伤害最高）
}

# --- 关卡主题 ---
enum LevelTheme {
    BIOHAZARD = 0,   # 生化实验区
    PLANT = 1        # 植物实验区
}

# --- 噪声区间 ---
enum NoiseZone {
    GREEN = 0,       # 0-50 安全
    YELLOW = 1,      # 51-120 警告
    RED = 2          # 121-199 临界
}
```

---

## 7. 每个 Resource 类的字段定义

### 7.1 WeaponData（`scripts/data/weapon_data.gd`）

```gdscript
class_name WeaponData
extends Resource

## 武器名称（如"手枪"、"霰弹枪"）
@export var weapon_name: String = ""

## 武器类型（手枪/霰弹枪/近战/步枪）
@export var weapon_type: int = GameEnums.WeaponType.PISTOL

## 武器图标 — 在 Inspector 中点一下即可替换图片
@export var icon: Texture2D

## 单发/单颗弹丸伤害（稀有度乘数在伤害管线中另外应用）
@export var damage: float = 15.0

## 射击间隔（秒），数值越小射速越快，近战武器也适用
@export var fire_rate: float = 0.4

## 弹匣容量，0 = 不需要换弹（近战武器）
@export var mag_size: int = 12

## 换弹时间（秒），0 = 无需换弹
@export var reload_time: float = 1.5

## 换弹模式：0=弹匣式 1=逐发装填 2=无
@export var reload_mode: int = GameEnums.ReloadMode.MAGAZINE

## 有效射程（像素），超出后伤害平方衰减（保底10%）。近战武器 = hitbox_range
@export var range: float = 400.0

## 每次开火的噪声值
@export_range(0, 100) var noise: int = 30

## 弹丸数，默认 1，霰弹枪设为 5
@export var pellets: int = 1

## 散布角（度），霰弹 25°，手枪 2°
@export var spread: float = 2.0

## 稀有度
@export var rarity: int = GameEnums.Rarity.COMMON

## 特殊效果列表（从 BuffType 枚举中选取）
@export var effects: Array[int] = []

## 近战碰撞体形状（"arc"扇形 / "rect"矩形），仅近战武器使用
@export var hitbox_shape: String = "arc"

## 近战扇形角度，仅近战武器使用
@export var hitbox_angle: float = 120.0
```

### 7.2 NoiseConfig（`scripts/data/noise_config.gd`）

```gdscript
class_name NoiseConfig
extends Resource

## 临时噪声每秒衰减量
@export var temp_decay_per_second: float = 8.0

## 残留噪声转换率（每次临时噪声产生时，该比例的数值同步加入残留）
@export_range(0.0, 1.0) var residual_conversion_rate: float = 0.15

## 残留噪声每10秒衰减量
@export var residual_decay_per_10s: float = 2.0

## Boss 苏醒阈值：临时噪声 + 残留噪声 >= 此值 → Boss 苏醒
@export var boss_threshold: float = 200.0

## 绿色区上限（0 到此值为安全区）
@export var zone_green_ceiling: float = 50.0

## 黄色区上限（绿色区到此值为警告区）
@export var zone_yellow_ceiling: float = 120.0

## 红色区上限（黄色区到此值为临界区）
@export var zone_red_ceiling: float = 199.0
```

### 7.3 MonsterData（`scripts/data/monster_data.gd`）

```gdscript
class_name MonsterData
extends Resource

## 怪物名称
@export var monster_name: String = ""

## 怪物层级（杂兵/精英/小Boss）
@export var tier: int = GameEnums.MonsterTier.GRUNT

## 所属关卡主题
@export var level_theme: int = GameEnums.LevelTheme.BIOHAZARD

## 生命值
@export var hp: float = 30.0

## 移动速度（相对于玩家走路速度的倍数）
@export var move_speed: float = 0.8

## 视觉感知距离（像素），0=无视觉
@export var vision_range: float = 200.0

## 听觉感知：触发 Alert 的最低噪声等级
@export var hearing_threshold: int = GameEnums.NoiseLevel.MEDIUM

## 听觉感知距离（像素）
@export var hearing_range: float = 400.0

## 天然护甲减伤比例（0.0-1.0），Boss 可用
@export_range(0.0, 1.0) var natural_armor: float = 0.0

## Alert 暂停观察时长（秒），精英更短，Boss 不使用
@export var alert_pause_duration: float = 0.5

## Search 搜索时长（秒）
@export var search_duration: float = 8.0

## 是否有 walk 动画（Boss 为 false）
@export var has_walk: bool = true

## 攻击技能列表（数组中的每个元素是 AttackData Resource）
@export var attacks: Array[AttackData] = []

## 怪物外观 Sprite（S0 阶段可用 Texture2D 或直接不用——由场景节点提供外观）
@export var sprite: Texture2D
```

### 7.4 AttackData（`scripts/data/attack_data.gd`）

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

## 攻击范围（像素），仅近战/冲锋/喷洒使用
@export var attack_range: float = 64.0

## AOE 半径（像素），仅 AOE 类攻击使用
@export var aoe_radius: float = 80.0

## 碰撞时是否停止（冲锋等撞墙会停）
@export var stop_on_wall: bool = false

## 撞墙后眩晕时长（秒），仅冲锋类
@export var wall_stun_duration: float = 2.0

## 弹丸数，仅弹道类使用
@export var projectile_count: int = 1

## 散布角（度），仅弹道类使用
@export var spread: float = 0.0

## 持续区域时长（秒），仅持续区域类使用
@export var zone_duration: float = 0.0

## 此攻击属于 Boss 哪个阶段（0=全阶段 1=P1 2=P2 3=P3）
@export var boss_phase: int = 0
```

### 7.5 ArmorData（`scripts/data/armor_data.gd`）

```gdscript
class_name ArmorData
extends Resource

## 防具名称
@export var armor_name: String = ""

## 装备部位：0=头 1=胸 2=腿
@export var slot: int = 0

## 减伤比例（0.0-1.0，命中该部位时 damage × (1-DR)）
@export_range(0.0, 1.0) var damage_reduction: float = 0.3

## 耐久度上限
@export var max_durability: int = 3

## 特殊效果描述（如"减少噪声产生10%"）
@export var special_effect: String = ""
```

### 7.6 ConsumableData（`scripts/data/consumable_data.gd`）

```gdscript
class_name ConsumableData
extends Resource

## 消耗品名称
@export var item_name: String = ""

## 消耗品类型：0=弹药箱 1=投掷物 2=医疗 3=其他
@export var item_type: int = 0

## 携带上限
@export var max_carry: int = 2

## 使用时产生的噪声值
@export var noise_on_use: int = 0

## 物品图标
@export var icon: Texture2D

## 使用音效
@export var use_sound: AudioStream

# --- 仅投掷物需要以下字段 ---

## 投掷物子类型（0=信号弹 1=烟雾弹 2=手榴弹 3=噪声地雷）
@export var throwable_subtype: int = 0

## 触发后产生的噪声值（仅地雷）
@export var noise_on_trigger: int = 0

## 触发半径（像素，仅地雷）
@export var trigger_radius: float = 150.0

## 爆炸半径（像素，手榴弹/地雷）
@export var blast_radius: float = 60.0

## 爆炸伤害
@export var blast_damage: float = 0.0
```

### 7.7 BuffData（`scripts/data/buff_data.gd`）

```gdscript
class_name BuffData
extends Resource

## Buff 名称
@export var buff_name: String = ""

## Buff 类型
@export var buff_type: int = GameEnums.BuffType.PIERCE

## 此 Buff 需要的最低稀有度
@export var required_rarity: int = GameEnums.Rarity.UNCOMMON

## 是否在 MVP 阶段实现
@export var is_mvp: bool = true
```

---

## 8. 核心系统数值速查

### 8.1 噪声动作分级

| 噪声等级 | 数值范围 | 具体动作 |
|------|:--:|------|
| 零 | 0 | 站立、被击中、完美格挡、喝血瓶、开背包 |
| 微 | 1-3 | 走路、切换武器、手电筒开关 |
| 低 | 4-8 | 跑步、翻滚 |
| 中 | 9-16 | 换弹 |
| 中高 | 17-25 | 近战攻击（撬棍=20） |
| 高 | 26-60 | 枪械开火（手枪=30、步枪=45、霰弹=55） |
| 极高 | 61-90 | 爆炸物、破门 |
| 特大 | 91+ | 修复电源 |

> **原则**：噪声 = 玩家主动行为。被敌人打 = 0（扣血已是惩罚）。完美格挡 = 0（防御成功）。

### 8.2 噪声衰减参数

| 参数 | 值 |
|------|:--:|
| 临时噪声衰减 | −8/秒 |
| 残留转换率 | 15%（每次临时噪声 15% 同步加入残留） |
| 残留衰减 | −2/10秒 |
| Boss 苏醒阈值 | 200（临时 + 残留 ≥ 200） |
| 绿区 | 0-50 |
| 黄区 | 51-120 |
| 红区 | 121-199 |

### 8.3 MVP 武器基准数值（普通/白板）

| 属性 | 手枪 | 霰弹枪 | 撬棍 |
|------|:--:|:--:|:--:|
| damage | 15 | 6 | 25 |
| fire_rate | 0.4 | 0.8 | 0.8 |
| mag_size | 12 | 6 | 0 |
| reload_time | 1.5 | 3.0 | 0 |
| reload_mode | 弹匣式(0) | 逐发装填(1) | 无(2) |
| range | 400 | 200 | 64 |
| noise | 30 | 55 | 20 |
| pellets | 1 | 5 | — |
| spread | 2° | 25° | — |
| rarity | 普通 | 普通 | 普通 |

### 8.4 稀有度数值乘数

| 稀有度 | damage 乘数 | 其他属性乘数 | Buff 槽数 |
|------|:--:|:--:|:--:|
| 普通(白) | ×1.0 | ×1.0 | 0 |
| 精良(绿) | ×1.2 | ×1.0 | 1 |
| 稀有(蓝) | ×1.4 | ×1.05 | 1 |
| 史诗(紫) | ×1.7 | ×1.1 | 2 |
| 传说(金) | ×2.0 | ×1.15 | 2 + 专属 |

### 8.5 MVP Buff（5 个）

| Buff | 稀有度 | 类别 | 效果 |
|------|:--:|------|------|
| 穿透 | 精良 | 弹道 | 子弹命中后不消失，穿透 1 个目标 |
| 燃烧 | 精良 | 状态 | 命中附加 2 秒 DoT（每秒 damage×0.3），目标被短暂照亮 |
| 抑制 | 稀有 | 噪声 | 武器噪声 −15 |
| 双发 | 稀有 | 弹道 | 一次开火射 2 颗子弹（只耗 1 发弹药），独立散布 |
| 爆炸 | 史诗 | 弹道 | 命中产生半径 80px AOE（伤害×0.5），额外 +15 噪声 |

**非 MVP Buff（后续实现）**：弹射、暗影步、吸血。

### 8.6 消耗品

| 物品 | 携带上限 | 快捷槽 |
|------|:--:|:--:|
| 弹药箱 | 2 | ①（键位 3） |
| 肾上腺素 | 1 | ①（键位 3）共用 |
| 手榴弹 | 2 | ②（键位 4）投掷物池 |
| 烟雾弹 | 2 | ②（键位 4）投掷物池 |
| 信号弹 | 2 | ②（键位 4）投掷物池 |
| 噪声地雷 | 2 | ②（键位 4）投掷物池 |

血瓶独立于消耗品系统：初始 3 次、每次回复 30-35% HP、安全屋补满、不占槽、按键 Q。

---

## 9. 伤害计算管线（9步）

**Codex 必须严格按以下顺序实现，每一步有明确的输入/输出。**

```
① 攻击发起
   READ weapon_data.tres → 组装攻击参数包 {
     damage, pellets, spread, range, noise,
     effects: [], is_aiming: bool, is_melee: bool,
     hitbox_shape, hitbox_angle, hitbox_range,
     attacker_pos: Vector2, direction: Vector2
   }
   若 is_aiming：spread = spread × 0.5

② 命中判定
   远程武器：for i in range(pellets):
              angle = direction + random(-spread, +spread)
              raycast(attacker_pos, angle, range) → {目标, 距离}
   近战武器：Area2D（扇形或矩形）→ 检测范围内所有怪物碰撞体
   碰撞体：怪物只有一个碰撞体，不区分头/躯干/腿

③ 命中登记
   命中数 n。每条含 {target, distance}
   n=0：产生噪声但不进入后续步骤

④ 距离衰减
   仅远程武器。命中距离 > weapon.range：
     falloff = (range / distance)²
     damage = damage × falloff
     下限 ≥ 基础 damage × 0.1

⑤ 防具减伤
   damage = damage × (1 - target.armor.damage_reduction)
   防具耐久 -1（每次命中消耗 1 耐久）
   若耐久归零 → 防具破损
   近战同样走此步
   怪物可能没有防具（DR=0）

⑥ 瞄准加成
   if (is_aiming AND NOT is_melee):
       damage = damage × 1.3

⑦ 稀有度乘数
   damage = damage × rarity_multiplier
   (放在防具减伤之后，高稀有度对破甲有天然优势)

⑧ 特殊效果处理
   for effect in weapon.effects[] (按优先级排序):
       触发对应效果逻辑
   优先级：twin_shot(②阶段已处理) → incendiary(DoT) → 
            pierce(射线延续) → explosive(AOE) → roll_reset/vampiric(击杀后)

⑨ 最终扣血
   target.HP -= final_damage
   触发受击反馈：浮动数字 + 屏幕闪红 + 手柄震动
   如果 target.HP <= 0：发射 monster_killed 信号
```

---

## 10. 怪物状态机（6态）

**全部怪物共用同一套状态定义。** Boss 的行为区别标注在下表中。

```
         ┌──────────┐
         │   Idle   │ 全部怪物（Boss=沉睡呼吸，杂兵/精英=站岗待机）
         └────┬─────┘
              │ Boss：噪声≥阈值 或 电源修复 → Combat
              │ 杂兵/精英：玩家进入感知范围 → Patrol
              ▼
         ┌──────────┐
         │  Patrol  │ 仅杂兵/精英（Boss 不巡逻）
         └────┬─────┘
              │ 听到噪声(≥阈值) 或 看到玩家 → Alert
              │ 受到伤害 → Combat
              ▼
         ┌──────────┐
         │  Alert   │ 仅杂兵/精英（先 idle 暂停 → walk 走向刺激源）
         └────┬─────┘
              ├─ 暂停中玩家离开视线 → 取消，回 Patrol
              ├─ 到达后搜索无发现 → Patrol
              ├─ 看到玩家 → Combat
              └─ 受到伤害 → Combat
              ▼
         ┌──────────┐
         │  Combat  │ 全部怪物
         └────┬─────┘
              ├─ Boss 移动：walk 动画不使用，位移全部由攻击动作完成
              │   （冲锋/扑击/触手拖拽/钻地），攻击间隙静止 idle
              ├─ 杂兵/精英 移动：walk 追击
              ├─ 丢失目标 > 5s → Search（仅杂兵/精英）
              ├─ Boss 血量阈值 → 转阶段动画（无敌 1.5s）
              └─ 血量归零 → Dead
              ▼
         ┌──────────┐
         │  Search  │ 仅杂兵/精英（最后位置附近 walk 搜索）
         └────┬─────┘
              ├─ 发现玩家 → Combat
              ├─ 听到噪声 → Alert
              └─ 超时 → 在丢失位置附近随机游荡（不回原始 Patrol 路径）
              ▼
         ┌──────────┐
         │   Dead   │ 全部怪物。尸体保留到关卡结束
         └──────────┘
```

### Boss 特殊规则

1. **苏醒**：Idle（沉睡）→ 噪声累积 ≥ 200 或电源修复 → Combat
2. **追击**：Combat 中全图感知，定向追踪玩家
3. **追丢**：丢失目标 5s → 进入**全图随机游荡**（不回沉睡！）
4. **再发现**：游荡中感知到玩家 → 立刻恢复追击
5. **安全屋**：Boss 被力场排斥，不能进入安全屋。在门外等待后放弃，转入游荡
6. **移动**：Boss 不使用 walk。所有位移由攻击动作实现（冲锋、扑击、触手拖拽、钻地）
7. **转阶段**：血量到 70%/40% → 1.5s 无敌转阶段动画 → Combat（新技能池）

---

## 11. 全局操作键映射

| 按键 | 功能 | 噪声 |
|:--:|------|:--:|
| WASD | 移动 | 1-3 / 4-8 |
| Shift | 走路 ⇄ 跑步切换 | — |
| 空格 | 翻滚（有 CD） | 4-8 |
| 鼠标左键 | 统一攻击（当前武器决定近战/射击） | 20 / 30-55 |
| 鼠标右键 | 枪械=瞄准 / 近战=格挡 | 0 |
| R | 换弹 | 9-16 |
| Q | 血瓶（葫芦） | 0 |
| T | 手电筒开关 | 1-3 |
| E | 交互（搜刮/开门/修电源/安全屋） | 0-91+ |
| Tab | 打开背包 | 0 |
| 1 / 2 | 切换武器到槽①/槽② | 1-3 |
| 3 | 使用快捷物品① | 视物品 |
| 4 | 使用投掷物（快捷物品②） | 视物品 |
| 5 / 6 | 使用快捷物品③/④ | 视物品 |
| 滚轮 | 循环切换武器 | 1-3 |

---

## 12. 快捷槽与 HUD 布局

```
═══════════════════════════════════════════
 独立区（不占快捷槽）
   ❤️❤️❤️  3/3         血瓶（Q 键）
   🔫 手枪  12/24        弹药数
   💥 霰弹  4/12         弹药数
═══════════════════════════════════════════
 4 格快捷槽
   ① 弹药箱/肾上腺素  键位 3（共用一槽，背包切换）
   ② 投掷物槽        键位 4（四选二装入，按键轮换）
   ③ 自由分配        键位 5（MVP 暂空）
   ④ 自由分配        键位 6（MVP 暂空）
═══════════════════════════════════════════
```

HUD 还需显示：
- 噪声条（绿/黄/红三区 + 屏幕边缘泛红/颤抖特效）
- 当前武器名称
- Boss 血条（Boss 战中显示）

---

## 13. 背包交互模型

参考塔科夫/暗黑破坏神的拖拽交互：

- 打开背包（Tab）→ 半透明覆盖，游戏暂停或极慢
- 右侧：背包网格（物品存放区域）
- 左上：武器栏 2 格（键位 1/2 对应）
- 左下：快捷栏 4 格（键位 3/4/5/6 对应）
- 拖拽物品到对应槽位 = 装备
- 右键物品 = 快速装备/卸下
- 武器只能放入武器槽，消耗品只能放入快捷槽

---

## 14. 玩家死亡系统

```
被击杀
  → 死亡动画
  → 屏幕黑屏 + 显示"物品丢失"文字
  → 黑幕加载
  → 回到基地（牢房）
  
✅ 保留：金币、技能点、已解锁技能节点、通行证
❌ 失去：当前关卡进度、携带武器/防具/消耗品
🔄 重置：地图重新随机生成、怪物全重置、Boss 回沉睡、噪声归零
```

**世界观解释**：主角被实验赋予了不死性。死亡 = 时间回溯。

---

## 15. EventBus 全局信号

`EventBus` 是 Autoload 单例，所有系统通过它通信。Codex 写每个系统时，**只发射和监听这些信号**，不直接引用其他系统的节点。

```gdscript
# scripts/core/event_bus.gd (Autoload)
extends Node

# --- 噪声 ---
signal noise_changed(temp_noise: float, residual_noise: float, zone: int)
signal boss_threshold_reached()

# --- 攻击 ---
signal shot_fired(weapon_data: WeaponData, position: Vector2, direction: Vector2)
signal melee_swung(weapon_data: WeaponData, position: Vector2)
signal damage_dealt(final_damage: float, target: Node2D, is_aimed: bool)

# --- 怪物 ---
signal monster_state_changed(monster: Node2D, old_state: int, new_state: int)
signal monster_alerted(monster: Node2D, alert_source: Vector2)
signal monster_killed(monster: Node2D, killer: Node2D)
signal boss_phase_changed(phase: int)
signal boss_awaken()

# --- 玩家 ---
signal player_died()
signal player_respawned()
signal player_health_changed(current_hp: float, max_hp: float)

# --- 物品 ---
signal item_picked_up(item_data: Resource, quantity: int)
signal item_used(item_data: Resource)
signal weapon_switched(slot_index: int, weapon_data: WeaponData)
signal flask_refilled()

# --- 地图 ---
signal safe_house_discovered(house_id: int)
signal power_restored(area_id: int)

# --- 场景 ---
signal scene_transition_started(from_scene: String, to_scene: String)
signal scene_transition_finished(new_scene: String)
```

---

## 16. 工作流：Codex 收到任务后

1. **确认**：读懂接口定义（函数签名、信号、参数格式）。有不清晰的立刻问 Claude Code。
2. **实现**：写 `.gd` / `.tres` / `.tscn`，严格遵循上述标准。
3. **自查**：
   - 每个 `@export` 都有 `##` 中文注释？
   - 没有硬编码数值？
   - 函数签名和接口定义一致？
   - 信号发射到了 EventBus？
4. **交付**：把文件内容或创建的文件告诉 Claude Code。
5. **等待集成**：Claude Code 负责把代码挂到 Autoload、注册信号、提交 Git。

---

## 17. 特别注意事项

### ⚠️ 已废弃的设计（不要实现）

| 废弃内容 | 替代方案 |
|------|------|
| 命中部位（头/躯干/腿） | 怪物单碰撞体 |
| 弱点爆头 | 瞄准无条件 ×1.3 |
| 普通格挡（减伤80%） | 格挡二元判定（完美格挡/失败） |
| 地面材质噪声区别 | 已砍掉——地面不产生额外噪声 |
| 扩容 Buff | 纯数值不改玩法，已砍 |
| 弹药回收 Buff | 25% 概率不可控，已砍 |
| 哑弹 Buff | 怪物无死亡噪声，Buff 无意义，已砍 |
| 减速 Buff | 和燃烧定位重叠，已砍 |
| 击退 Buff | MVP 无地形支撑，已砍 |

### ⚠️ GDD 中的过时描述

`game-design-decisions.md` 中有些早期章节包含过时的数值（如特殊效果池那一段还列了 `headshot`）。**以下面这些章节为最终真相源**：
- Phase 3 噪声动作分级（最终版）
- Phase 3 武器数值框架
- Phase 3 伤害计算流程
- Phase 3 武器 Buff 系统
- Phase 3 怪物图鉴（MVP）
- Phase 3 按键与槽位体系

### ⚠️ Boss 无 walk 动画

Boss 的移动全部由攻击动作实现。它不像普通怪物那样播放 walk 动画来巡逻——它没有 walk。Codex 不要在 Boss 的 AnimationPlayer 里创建 walk 动画轨道。

---

## 18. Claude Code 联系方式

如果遇到任何不清楚的设计决策、接口定义模糊、或者需要 Claude Code 做集成配置——在当前对话中反馈，Claude Code 会处理。

**Codex 负责写代码 + 拼场景 + 填 .tres，Claude Code 负责所有其他事情。**
