# Codex 系统参考 — 数值表 + 伤害管线 + 状态机 + 按键 + EventBus

---

## 噪声动作分级表

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

> 核心原则：噪声 = 玩家**主动**行为。被敌人打 = 0（扣血已是惩罚）。完美格挡 = 0（防御成功）。

---

## 噪声衰减参数

| 参数 | 值 | 说明 |
|------|:--:|------|
| 临时衰减 | −8/秒 | 手枪 30→0 需 4s，霰弹 55→0 需 7s |
| 残留转换率 | 15% | 每次产生临时噪声时 15% 同步加入残留 |
| 残留衰减 | −2/10秒 | 残留 20 约 100s 全消 |
| Boss 阈值 | 200 | 临时 + 残留 ≥ 200 |
| 绿区 | 0-50 | 安全，无视觉反馈 |
| 黄区 | 51-120 | 警告，屏幕边缘微红 |
| 红区 | 121-199 | 临界，屏幕深红 + 颤抖 + 手柄震动 |

每帧：`if (temp_noise + residual_noise >= 200): EventBus.boss_threshold_reached.emit()`

---

## MVP 武器基准数值（普通/白板）

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

---

## 稀有度乘数

| 稀有度 | damage 乘数 | 其他属性乘数 | Buff 槽数 |
|------|:--:|:--:|:--:|
| 普通(白) | ×1.0 | ×1.0 | 0 |
| 精良(绿) | ×1.2 | ×1.0 | 1 |
| 稀有(蓝) | ×1.4 | ×1.05 | 1 |
| 史诗(紫) | ×1.7 | ×1.1 | 2 |
| 传说(金) | ×2.0 | ×1.15 | 2 + 专属 |

---

## Buff 清单

| Buff | 稀有度 | 类别 | 效果 | MVP |
|------|:--:|------|------|:--:|
| 穿透 | 精良 | 弹道 | 子弹命中后不消失，穿透 1 个目标 | ✅ |
| 燃烧 | 精良 | 状态 | 命中附加 2s DoT（damage×0.3/秒），目标被照亮 | ✅ |
| 抑制 | 稀有 | 噪声 | 武器噪声值 −15 | ✅ |
| 双发 | 稀有 | 弹道 | 一次开火 2 发子弹（只耗 1 发弹药），独立散布 | ✅ |
| 爆炸 | 史诗 | 弹道 | 命中产生 80px AOE（damage×0.5），额外 +15 噪声 | ✅ |
| 弹射 | 稀有 | 弹道 | 命中墙壁弹射 1 次，朝最近敌人偏转 | ❌ |
| 暗影步 | 传说 | 击杀 | 击杀重置翻滚 CD | ❌ |
| 吸血 | 传说 | 击杀 | 击杀回复 HP=最终伤害×5%（上限 10% 最大HP） | ❌ |

**MVP 只实现前 5 个。后 3 个后续版本再加。**

---

## 回复血瓶、消耗品与装备槽

| 装备槽 | 内容 | 容量 |
|------|------|:--:|
| 回复血瓶 | 回复血瓶一种类型 | 按物品堆叠，`Q` 使用 |
| 消耗品 | 弹药箱、肾上腺素等非治疗物品一种类型 | 按物品堆叠，`F` 使用 |
| 投掷物 1 | 信号弹 / 烟雾弹 / 手榴弹 / 噪声地雷之一 | 按物品堆叠 |
| 投掷物 2 | 信号弹 / 烟雾弹 / 手榴弹 / 噪声地雷之一 | 按物品堆叠 |

回复血瓶槽通过 `Q` 使用；消耗品槽通过 `F` 使用。两者必须拥有独立图标、数量、冷却/使用状态和动画反馈。鼠标点击投掷物槽进行选择，普通投掷物左键蓄力后松开，地雷左键长按原地安置。

背包是可配置容量的网格，未装备物品放在背包栏；装备栏和背包栏之间支持鼠标拖拽、交换和卸下。

投掷物伤害排序：地雷 > 手榴弹 > 烟雾弹 = 信号弹 = 0

---

## 投掷物详情

| 投掷物 | 核心用途 | 直接伤害 | 噪声 |
|------|------|:--:|:--:|
| 信号弹 | 照明 | 0 | 中 |
| 烟雾弹 | 遮蔽视线 | 0 | 低 |
| 手榴弹 | 范围杀伤 | 高 | 高（61-90） |
| 噪声地雷 | 诱敌陷阱 | 最高 | 触发后 +40 |

噪声地雷：投掷噪声 5。怪物进入 150px 范围或噪声≥30 在 200px 内波及即触发。触发后高频噪声 +40（持续 3s）+ 60px 爆炸伤害。

---

## 全局按键映射

| 按键 | 功能 | 噪声 |
|:--:|------|:--:|
| WASD | 移动 | 1-3 / 4-8 |
| Shift | 走路 ⇄ 跑步切换 | — |
| 空格 | 翻滚（有 CD） | 4-8 |
| 鼠标左键 | 统一攻击（当前武器决定近战/射击） | 20 / 30-55 |
| 鼠标右键 | 枪械=瞄准 / 近战=格挡（二元判定） | 0 |
| R | 换弹 | 9-16 |
| Q | 回复血瓶 | 0 |
| F | 消耗品（弹药箱、肾上腺素等） | 0 |
| T | 手电筒开关 | 1-3 |
| E | 交互 | 0-91+ |
| Tab | 背包 | 0 |
| 1/2 | 切换武器 | 1-3 |
| 3/4 | 选择投掷物槽 1/2 | — |
| 鼠标左键 | 当前武器攻击；选中投掷物时蓄力/释放或安置 | 视物品 |
| 滚轮 | 循环武器 | 1-3 |

> 当前快捷栏视觉顺序为 `1/2/3/4/Q/F`：1/2 是武器，3/4 选择两个投掷物槽，Q/F 分别使用回复血瓶和普通消耗品。逻辑槽位 ID 保持独立不变。

---

## 格挡参数

| 参数 | 值 | 说明 |
|------|:--:|------|
| 窗口时长 | 0.2s（12帧@60fps） | 按下右键立即进入窗口，无前摇 |
| 失败硬直 | 0.4s | 比正常受击硬直短 |
| CD | 0.5s | 格挡后无论成败短暂 CD |

| 结果 | 伤害 | 噪声 | 敌人 |
|------|:--:|:--:|------|
| 完美格挡（窗口内） | 0 | 0 | 硬直，可接反击（伤害×1.5） |
| 格挡失败（窗口外） | 全额 | 0 | 继续行动 |

有 ground: 弹道投射 / 范围喷洒 / AOE / 跳跃 / 钻地 / 持续区域 — 不可格挡。

---

## 右键瞄准

| 收益 | 代价 |
|------|------|
| spread × 0.5（散布减半） | 移速 × 0.5 |
| 命中伤害 × 1.3 | 不可跑步 |
| 手电筒光束收窄、照更远 | 侧翼视野收窄 |

---

## 9 步伤害管线

```
① 攻击发起
   READ weapon_data.tres → 组装参数包 {
     damage, pellets, spread, range, noise,
     effects: [], is_aiming: bool, is_melee: bool,
     hitbox_shape, hitbox_angle, hitbox_range,
     attacker_pos: Vector2, direction: Vector2
   }
   若 is_aiming → spread × 0.5

② 命中判定
   远程：for i in pellets: raycast(angle + random(spread)) → {target, distance}
   近战：Area2D 扇形/矩形 → 检测范围所有怪物碰撞体
   怪物单碰撞体，不分部位

③ 命中登记
   命中数 n，每条含 {target, distance}
   n=0 → 只产 noise 不进后续

④ 距离衰减（仅远程）
   if distance > weapon.range:
     falloff = (range / distance)²
     damage ×= falloff
     下限 ≥ damage × 0.1

⑤ 防具减伤（近战远程都走）
   damage ×= (1 - target.armor.damage_reduction)
   防具耐久 -1
   耐久归零 → 破损

⑥ 瞄准加成
   if is_aiming AND NOT is_melee: damage ×= 1.3

⑦ 稀有度乘数
   damage ×= rarity_multiplier

⑧ 特殊效果
   for effect in effects[] 按优先级：
     incendiary(DoT) → explosive(AOE+15噪声) →
     pierce/twin_shot(在②阶段已处理) →
     roll_reset/vampiric(击杀后触发)

⑨ 最终扣血
   target.HP -= final_damage
   受击反馈：浮动数字 + 屏幕闪红 + 手柄震动
   HP≤0 → EventBus.monster_killed.emit()
```

---

## 怪物 6 态状态机

```
         ┌──────────┐
         │   Idle   │ （全部怪物。Boss=沉睡，杂兵/精英=站岗）
         └────┬─────┘
     感知触发 │ Boss：噪声≥200 或电源修复→Combat
              ▼ 杂兵/精英：感知→Patrol
         ┌──────────┐
         │  Patrol  │ （仅杂兵/精英。Boss 不巡逻）
         └────┬─────┘
     噪声/视觉 │ 受到伤害
              ▼
         ┌──────────┐
         │  Alert   │ （仅杂兵/精英。暂停idle→walk走向刺激源）
         └────┬─────┘
   暂停中玩家离开→取消回Patrol  │ 到达搜索无发现→Patrol
   看到玩家/受到伤害           │
              ▼
         ┌──────────┐
         │  Combat  │ （全部怪物）
         └────┬─────┘
   杂兵/精英丢失>5s→Search  │ Boss丢失>5s→全图游荡(不回Patrol!)
   血量归零→Dead            │ Boss血量70%/40%→转阶段动画(1.5s无敌)→回Combat
              ▼
         ┌──────────┐
         │  Search  │ （仅杂兵/精英。最后位置附近walk搜索）
         └────┬─────┘
   超时→在丢失位置附近**随机游荡(不回原始Patrol路径!)**
   发现玩家→Combat / 听到噪声→Alert
              ▼
         ┌──────────┐
         │   Dead   │ （全部怪物。尸体保留）
         └──────────┘
```

## Boss 特殊规则

1. 苏醒前沉睡(Idle)，噪声≥200 或电源修复→直接进 Combat
2. Boss 无 walk 动画，位移全部由攻击动作实现（冲锋/扑击/钻地/触手拖拽）
3. 攻击间隙静止 idle（喘息/咆哮）
4. 追丢玩家→全图随机游荡（不回沉睡）
5. 游荡中感知到玩家→立刻恢复追击
6. 安全屋力场阻挡 Boss 进入
7. 死亡=整局重置→Boss 回初始 Idle

---

## EventBus 全局信号

文件：`scripts/core/event_bus.gd`（Autoload 单例）

```gdscript
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
