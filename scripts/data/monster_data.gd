class_name MonsterData
extends Resource

## 怪物名称。
@export var monster_name: String = ""

## 怪物最大生命值，为后续伤害系统预留。
@export var max_health: float = 30.0

## 怪物移动速度（像素/秒）。
@export var move_speed: float = 70.0

## 怪物发现玩家的距离（像素）。
@export var vision_range: float = 280.0

## 怪物进入攻击状态的距离（像素）。
@export var attack_range: float = 48.0

## 攻击动作持续时间（秒）。
@export var attack_duration: float = 0.7

## 角色动画前缀，例如 demon 或 bloodmonster。
@export var animation_prefix: String = "demon"

## 动画资源目录。
@export var animation_base_path: String = "res://assets/runtime/monsters/"

## 怪物显示缩放。
@export var sprite_scale: float = 1.5

