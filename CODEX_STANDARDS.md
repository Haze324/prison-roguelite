# Codex 编码规范 + 美术标准

---

## 规则 1：数值永不硬编码

**所有**武器伤害、怪物 HP、噪声值、衰减速率等数值必须定义在 `.tres` Resource 文件中。逻辑代码只读 `.tres` 字段，不自带任何数值常数。

```
✅ damage_pipeline.gd 写：  var dr = target.armor.damage_reduction
❌ damage_pipeline.gd 写：  var dr = 0.3  # 胸甲减伤30%
```

**例外**：数学常数（PI）、引擎常量（TAU）可以使用。

## 规则 2：所有 @export 必须中文注释

每一个 `@export` 变量上方都要有 `##` 注释。Godot Inspector 中鼠标悬停在这个字段上时会弹出这个中文提示——策划/美术不需要看代码就能理解。

```gdscript
# ✅ 正确
## 单发基础伤害（稀有度乘数在管线中另外应用）
@export var damage: float = 15.0

## 弹匣容量，0 = 不需要换弹（近战武器）
@export var mag_size: int = 12

# ❌ 错误——没有注释，策划在 Inspector 里不知道这数字干嘛的
@export var damage: float = 15.0
```

## 规则 3：美术资源全可视化替换

所有图片/音效/粒子等外部资源通过 `@export` 暴露。在 Godot 编辑器里点一下、拖一下就能换，不需要打开代码。

```gdscript
## 武器图标 — 点一下选图即可替换
@export var icon: Texture2D

## 开枪音效 — 拖 .wav/.mp3 到这里
@export var fire_sound: AudioStream

## 子弹场景预制体 — 拖 .tscn 到这里
@export var bullet_scene: PackedScene

## 怪物外观 — 拖图片到这里（S0 阶段可空着，用 Godot 原生节点拼外观）
@export var sprite: Texture2D
```

## 规则 4：系统间通信只走 EventBus

不同系统（如噪声系统和怪物系统）之间不直接引用节点。全部通过 `EventBus` Autoload 的信号通信。

```gdscript
# ✅ 正确——发射信号
EventBus.noise_changed.emit(temp, residual, zone)

# ✅ 正确——监听信号
EventBus.noise_changed.connect(_on_noise_changed)

# ❌ 错误——直接调用另一个系统的函数
$NoiseSystem.update_noise(temp)
```

## 规则 5：调参流程

```
改 .tres → 保存（Ctrl+S）→ Godot 热重载 → 立即生效
（零编译、零重启、不改代码）
```

策划可以在 Godot 编辑器中独立打开 `.tres`，在 Inspector 面板拖滑条调参。

---

## 文件命名规范

| 类型 | 规则 | 示例 |
|------|------|------|
| GDScript 类 | snake_case | `weapon_data.gd`, `noise_system.gd` |
| .tres 资源 | type_variant（武器=type_rarity_effect，怪物=name_level） | `pistol_common.tres`, `prisoner_var_lv1.tres` |
| .tscn 场景 | snake_case | `player.tscn`, `hud.tscn`, `main_menu.tscn` |
| 图片/音效 | snake_case | `prisoner_var_idle.png`, `pistol_fire.wav` |
| 目录 | snake_case | `scripts/data/`, `resources/weapons/` |

## GDScript 风格

- `class_name` 写在文件顶部，和文件名一致
- 只暴露必要的公开方法，内部逻辑用常规函数或 `static func`
- 不 `print()` 调试——用 `push_warning()` 或 `assert()`
- 函数签名严格匹配 COEX_DATA_DEFS.md 和 COEX_SYSTEMS_REF.md 中的定义

---

## S0 美术标准

### 色板

**生化实验区（关 1）— 6 色：**

| 色名 | 十六进制 | 用途 |
|------|------|------|
| 暗红 | `#4A1010` | 身体、主色调 |
| 肉粉 | `#C97B7B` | 头部、皮肤 |
| 深褐 | `#2C1A0E` | 正常肢体 |
| 血红 | `#8B0000` | 变异部位、眼睛 |
| 骨白 | `#D4C5B0` | 骨骼、牙齿 |
| 黑 | `#000000` | 轮廓、阴影 |

**植物实验区（关 2）— 6 色：**

| 色名 | 十六进制 | 用途 |
|------|------|------|
| 腐绿 | `#2D4A1E` | 主色调 |
| 暗紫 | `#3D1A4A` | 花苞、核心 |
| 苔黄 | `#6B7A2E` | 触须、藤蔓 |
| 绿荧 | `#4AFF3A` | 发光孢子、毒液 |
| 灰褐 | `#4A3D3D` | 枯死组织 |
| 黑 | `#000000` | 轮廓、阴影 |

### 画法

**全部在 Godot 编辑器内完成，零外部工具。** 用以下 Godot 原生节点拼怪物：

- `ColorRect` — 矩形部件（身体、手臂、腿）
- `Sprite2D` + 圆形纹理 — 头、眼睛
- 所有节点放在一个 `Node2D` 根下

```
变异囚犯（关 1）节点层级示例：
  VariantPrisoner (Node2D)
  ├── Body (ColorRect 暗红 32×48)
  ├── ArmLeft (ColorRect 深褐 28×8)
  ├── ArmRight (ColorRect 暗红 36×12)  ← 肿胀利爪，更大
  ├── Head (Sprite2D 肉粉圆形 r=10)
  ├── EyeL (ColorRect 血红 2×2)
  ├── EyeR (ColorRect 血红 2×2)
  └── AnimationPlayer
```

### 动画

全部 `AnimationPlayer` 关键帧，不需要 Sprite Sheet：

| 动画名 | 时长 | 内容 |
|------|:--:|------|
| `idle` | 1.5s | scale 1.0 ↔ 1.03 呼吸，上下微动 |
| `walk` | 0.8s | 左右平移 + 手臂前后摆动 |
| `attack` | 0.5s | 攻击臂 45° 挥出 + 收回 |
| `death` | 1.0s | scale 压扁 + modulate 变透明 |

Boss 不使用 walk 动画——它的位移全部由攻击动作完成。

### 可替换性

每个怪物/武器的 `@export var sprite: Texture2D` 字段预留了图片位置。S0 几何形 → S1 拖像素图 → 立刻更新，逻辑代码一行不动。
