extends Node

## 跨系统事件总线。实体内部优先使用本地信号，系统之间才使用这里。
signal player_state_changed(previous_state: String, next_state: String)
signal weapon_switched(slot_index: int, weapon_data: WeaponData)
signal shot_fired(weapon_data: WeaponData, position: Vector2, direction: Vector2)
signal dash_started(position: Vector2, direction: Vector2)
signal monster_state_changed(monster: Node2D, previous_state: String, next_state: String)
signal monster_alerted(monster: Node2D, source: Vector2)
signal monster_killed(monster: Node2D)
