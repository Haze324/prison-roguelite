class_name PlayerConfig
extends Resource

## 玩家移动速度（像素/秒）。
@export var move_speed: float = 250.0

## 跑步速度；按住跑步键时使用。
@export var run_speed: float = 340.0

## 走路与跑步的噪声值。
@export var walk_noise: int = 1
@export var run_noise: int = 6

## 翻滚/冲刺速度（像素/秒）。
@export var dash_speed: float = 800.0

## 翻滚/冲刺持续时间（秒）。
@export var dash_duration: float = 0.2

## 翻滚/冲刺冷却时间（秒）。
@export var dash_cooldown: float = 0.8

## 玩家碰撞半径（像素）。
@export var collision_radius: float = 18.0

## 角色显示缩放。
@export var body_scale: float = 1.5

## 武器挂点相对玩家中心的偏移。
@export var hand_offset: Vector2 = Vector2(18.0, -8.0)

## 最大生命值。
@export var max_health: float = 100.0
