class_name WeaponData
extends Resource

## 武器名称。
@export var weapon_name: String = ""

## 武器图像。
@export var icon: Texture2D

## 单发基础伤害，后续由伤害管线读取。
@export var damage: float = 15.0

## 弹匣容量；近战武器可设为 0。
@export var mag_size: int = 12

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
