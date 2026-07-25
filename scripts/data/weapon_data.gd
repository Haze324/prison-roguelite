class_name WeaponData
extends Resource

## 武器名称。
@export var weapon_name: String = ""

## 武器图像。
@export var icon: Texture2D

## 单发基础伤害，后续由伤害管线读取。
@export var damage: float = 15.0

## 两次射击之间的间隔（秒）。
@export var fire_rate: float = 0.4

## 武器每次主动开火产生的噪声。
@export var noise: int = 30

## 子弹散布角度（度）。
@export var spread: float = 2.0

