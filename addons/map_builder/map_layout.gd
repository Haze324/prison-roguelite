@tool
class_name MapLayout
extends Node2D

## 地图布局资源节点：供 Godot 编辑器保存房间和墙体矩形。
@export var rooms: Array[Rect2] = []
@export var walls: Array[Rect2] = []

