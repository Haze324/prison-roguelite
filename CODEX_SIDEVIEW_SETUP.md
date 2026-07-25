# Codex 任务：横板侧视 2D 射击项目搭建

> **上次变更**：视角从俯视角改为横板侧视（2026-07-25）
> **原因**：现有素材中怪物 + 武器都是侧视的，更匹配横板玩法

---

## 一、目标

搭建 Godot 项目骨架：横板侧视角色 + 可切换武器 + 怪物 + 基础移动/跳跃/翻滚/射击。

```
本项目 = 2D横板（左-右方向为主，可跳跃）
       + 像素风 + 恐怖战术射击
       + "噪声即资源"机制
```

---

## 二、资源位置

```
E:\Claude项目\2D横板射击游戏\assets\
├── 俯视角\                              ← 仅取用女角色
│   └── The Female Adventurer - Free\
│       └── The Female Adventurer - Free\
│           ├── Idle\Idle_Right_Down.png      ← 384×64 (6帧 × 64×64)
│           ├── Walk\walk_Right_Down.png      ← 384×64
│           ├── Dash\Dash_Right_Down.png      ← 384×64
│           ├── Death\death_Right_Down.png    ← 384×64
│           ├── Jump - NEW\Normal\Jump_Right_Down.png  ← 384×64
│           └── Shadow.png                    ← 48×64
│
├── 侧视角\
│   ├── Ranitayas Guns Pack (16+ pixelart guns)\
│   │   └── Ranitayas Guns Pack (16+ pixelart guns)\
│   │       ├── Pistols\        ← 手枪2把 (15×10px, 16×8px)
│   │       ├── Shotguns\       ← 霰弹2把 (43×11, 31×7)
│   │       ├── Smgs\           ← SMG 2把
│   │       ├── AssaultRifles\  ← 步枪2把
│   │       ├── MachineGuns\    ← 机枪2把
│   │       ├── SniperRifles\   ← 狙击2把
│   │       ├── Revolvers\      ← 左轮2把
│   │       └── Explosives\     ← 爆炸物2个
│   │
│   ├── 20 melee weapons\20 melee weapons\    ← 20把近战武器 (1024×1024高清)
│   │   ├── Crowbar .PNG
│   │   ├── Katana.PNG
│   │   ├── ... (共20把)
│   │
│   ├── Tiny RPG Character Asset Pack 02 -Free Demon_A&Blood Monster_A\
│   │   └── Characters(100x100 split)\
│   │       ├── Demon_A\Demon_A\       ← 恶魔怪物
│   │       │   ├── Demon_A_Idle.png     600×100 (6帧)
│   │       │   ├── Demon_A_Walk.png     800×100 (8帧)
│   │       │   ├── Demon_A_Attack01.png 700×100 (7帧)
│   │       │   ├── Demon_A_Attack02.png 700×100 (7帧)
│   │       │   ├── Demon_A_Death.png    400×100 (4帧)
│   │       │   └── Demon_A_Hurt.png     400×100 (4帧)
│   │       │
│   │       └── Blood Monster_A\Blood Monster_A\  ← 血怪
│   │           ├── Blood Monster_A_Idle.png
│   │           ├── Blood Monster_A_Walk.png
│   │           ├── Blood Monster_A_Attack01.png
│   │           ├── Blood Monster_A_Attack02.png
│   │           ├── Blood Monster_A_Death.png
│   │           └── Blood Monster_A_Hurt.png
│   │
│   └── Humble Gift - Paper UI System\    ← UI组件库（后续用）
│
├── audio\    ← 空
├── fonts\    ← 空
└── sprites\  ← 空
```

---

## 三、技术方案

### 3.1 角色动画

**方案**：取 Female Adventurer 的 `Right_Down` 单方向 Spritesheet，通过 `flip_h` 镜像实现左朝向。

```
向右走：body_sprite.play("walk") + body_sprite.flip_h = false
向左走：body_sprite.play("walk") + body_sprite.flip_h = true
```

**Spritesheet 切帧**：

| 动画 | 源文件 | 帧数 | FPS | 循环 |
|------|------|:--:|:--:|:--:|
| idle | Idle_Right_Down.png | 6 | 10 | ✅ |
| walk | walk_Right_Down.png | 6 | 12 | ✅ |
| jump | Jump_Right_Down.png | 6 | 10 | ❌ |
| dash | Dash_Right_Down.png | 6 | 15 | ❌ |
| death | death_Right_Down.png | 6 | 8 | ❌ |

每帧 = 64×64px，384÷6=64，竖条等分切。

### 3.2 武器挂载

**节点结构**：
```
Player (CharacterBody2D)
├── BodySprite (AnimatedSprite2D)     ← 角色身体动画
├── Shadow (Sprite2D)                 ← 地面阴影
├── HandMarker (Marker2D)             ← 手的位置标记
│   └── WeaponSprite (Sprite2D)       ← 武器贴图，挂在HandMarker下
└── CollisionShape2D
```

**武器切换**：换武器 = 换 `WeaponSprite.texture`
**朝向翻转**：`HandMarker.position.x` 取反 + `WeaponSprite.scale.x` 取反

### 3.3 武器适配说明

Ranitayas Guns 原始尺寸很小（手枪 ~15×10px），需缩放到 `WeaponSprite.scale = Vector2(3, 3)` 左右。

20 Melee Weapons 是 1024×1024 高清展示图，**不适合作场景武器**。近战武器 S0 用灰色矩形替代，图标可缩放到 64px 做 UI。

### 3.4 PNG 加载方式

Godot 4 编辑器环境下，直接用 `Image.load(path)` 绕过导入系统：

```gdscript
var img = Image.new()
img.load("res://path/to/sprite.png")
# 切帧
var fw = img.get_width() / frame_count
for i in range(frame_count):
    var frame = img.get_region(Rect2i(i * fw, 0, fw, img.get_height()))
    var tex = ImageTexture.create_from_image(frame)
    sf.add_frame("anim_name", tex, 1.0 / fps)
```

> ⚠️ 发布时需改为 `.import` 导入，S0 阶段不用管。

### 3.5 怪物

取 Demon_A 和 Blood Monster_A 的动画，100×100px/帧。

| 动画 | 帧数 | FPS | 循环 |
|------|:--:|:--:|:--:|
| idle | 6 | 5 | ✅ |
| walk | 8 | 8 | ✅ |
| attack | 7 | 10 | ❌ |
| hurt | 4 | 8 | ❌ |
| death | 4 | 6 | ❌ |

---

## 四、当前测试项目状态

```
test_project/
├── project.godot          ← 含输入映射(move_left/right, jump, dash, shoot, weapon_1-4)
├── main.tscn              ← 场景：Main→Camera+Background+Ground+Player(含BodySprite等)+Labels
├── main.gd                ← 逻辑脚本：动画+物理+武器+怪物
├── icon.svg
└── assets/
    ├── character/         ← 已复制Right_Down各动画png
    ├── weapons/           ← pistol/shotgun/smg/rifle png
    └── monsters/          ← demon_* + bloodmonster_* png
```

**已验证通过**：
- ✅ 角色 idle/walk/jump/dash/death 动画正常播放
- ✅ 武器切换（1-4键）实时替换武器贴图
- ✅ 角色朝向 + 武器跟着翻转
- ✅ 怪物 Spritesheet 切帧正确
- ✅ 移动/跳跃/翻滚物理正常

**测试项目运行**：
```
E:\godot\Godot_v4.6.2-stable_win64.exe\Godot_v4.6.2-stable_win64.exe --path "E:\Claude项目\2D横板射击游戏\test_project"
```

---

## 五、Codex 要做的事

### 5.1 正式项目搭建

在 `E:\Claude项目\2D横板射击游戏\` 根目录创建正式的 Godot 项目，参考 `test_project` 的实现。

### 5.2 目录结构

```
prison-roguelite/
├── project.godot
├── scripts/
│   ├── core/              ← EventBus, GameData (Autoload)
│   ├── entities/          ← player.gd, monster.gd, bullet.gd
│   ├── systems/           ← noise_system.gd, combat_system.gd
│   └── ui/                ← hud.gd, inventory.gd
├── resources/             ← .tres 数值文件
├── scenes/                ← .tscn
├── assets/
│   ├── character/         ← 复制 Female Adventurer Right_Down PNG
│   ├── weapons/           ← 复制枪械 PNG
│   ├── monsters/          ← 复制 Demon + Blood Monster PNG
│   └── ui/                ← Paper UI System 相关
└── addons/
```

### 5.3 具体任务

1. **创建正式 Godot 项目**，版本 4.6，配置 input_map（见 `test_project/project.godot`）
2. **复制素材文件**到正式项目的 assets/ 下
3. **搭建 Player 场景**（按 §3.1 + §3.2 节点结构）
4. **实现 player.gd**：
   - 移动（左右 + 跳跃 + 重力）
   - 翻滚（Shift，0.2s 冲刺 + 0.8s CD）
   - 武器挂载切换（2格槽，1/2键 + 滚轮）
   - 鼠标左键射击 + 右键瞄准（散布收紧，后续实现）
   - 朝向翻转逻辑
5. **实现 monster.gd**：
   - 状态机：idle → walk → attack → hurt → death
   - 基础巡逻AI
6. **搭建 Camera2D** 跟随玩家
7. **参考 test_project/main.gd** 中的 Spritesheet 切帧代码

### 5.4 S0 简化约定

- 武器手持视觉效果 = `WeaponSprite` 挂在 `HandMarker` 下（不画角色手持武器的逐帧动画）
- 开枪 = 枪口闪光（黄色 ColorRect 闪 0.05s）+ 控制台日志
- 近战武器图标用 20 Melee Weapons 缩小到 64px 做 UI，场景中不渲染近战武器
- 场景地面 = ColorRect 灰色块
- 怪物 AI = 简单左右巡逻

---

## 六、关键数值（从设计文档）

| 参数 | 值 |
|------|:--:|
| 重力 | 980 |
| 移速 | 250 |
| 跳跃速度 | -450 |
| 翻滚 CD | 0.8s |
| 翻滚时长 | 0.2s |
| 手枪噪声 | 30（后续接入） |
| 霰弹噪声 | 55 |
| 撬棍噪声 | 20 |
| 武器槽 | 2格，1/2键切换 |
| 攻击键 | 鼠标左键统一攻击 |

---

## 七、参考代码

`test_project/main.gd` 中的关键函数：

```gdscript
# Spritesheet 切帧
func setup_sprite_frames(sprite, base_path, {anim_name: [frames, fps, loop]})
# 武器加载
func load_weapon(idx)
# 玩家物理
func _physics_process(delta)  # 移动/跳跃/翻滚/射击
```

`test_project/project.godot` 中的 input_map 定义。

---

**有问题在对话中直接问 Claude Code。**
