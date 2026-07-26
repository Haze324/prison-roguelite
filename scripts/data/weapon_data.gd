class_name WeaponData
extends Resource

## 武器名称。
@export var weapon_name: String = ""

## 武器类别。
@export var weapon_type: int = GameEnums.WeaponType.PISTOL

## 武器图像。
@export var icon: Texture2D

## 运行时处理后的显示图标，不序列化到资源文件。
var display_icon: Texture2D

## 挂载到角色手部时的显示缩放。
@export var visual_scale: float = 0.8

## 近战武器独立显示缩放，允许在该武器 .tres 资源中单独调节。
@export var melee_visual_scale: float = 0.08

## 近战贴图握持端相对贴图中心的像素偏移。通过资源单独校准握持锚点。
@export var melee_grip_offset: Vector2 = Vector2.ZERO

## 近战贴图自身的基础旋转，用于将武器长轴对齐攻击方向。
@export var melee_rotation_offset: float = 0.0

## 单发基础伤害，后续由伤害管线读取。
@export var damage: float = 15.0

## 稀有度，影响基础伤害和 Buff 槽位。
@export var rarity: int = GameEnums.Rarity.COMMON

## 弹匣容量；近战武器可设为 0。
@export var mag_size: int = 12
@export var reserve_ammo: int = 24

## 换弹耗时；近战武器可设为 0。
@export var reload_time: float = 1.5

## 每次开火生成的弹丸数量。
@export var pellets: int = 1

## 两次射击之间的间隔（秒）。
@export var fire_rate: float = 0.4

## 武器每次主动开火产生的噪声。
@export var noise: int = 30

## 子弹散布角度（度）。
@export var spread: float = 2.0

## 子弹飞行速度。
@export var projectile_speed: float = 900.0

## 有效射程与散布控制。
@export var range: float = 400.0

## 是否为近战武器。
@export var is_melee: bool = false

## 近战攻击角度和范围。
@export var hitbox_angle: float = 120.0
@export var hitbox_range: float = 64.0

## Buff 类型数组，数值来自 GameEnums.BuffType。
@export var effects: Array[int] = []
