extends Node2D

@onready var player: Player = $Player
@onready var demon: Monster = $DemonGrunt
@onready var blood_monster: Monster = $BloodMonsterGrunt
@onready var status_label: Label = $HUD/Status
@onready var event_label: Label = $HUD/Event

var _last_event := "等待输入"

func _ready() -> void:
	demon.set_target(player)
	blood_monster.set_target(player)
	EventBus.weapon_switched.connect(_on_weapon_switched)
	EventBus.shot_fired.connect(_on_shot_fired)
	EventBus.dash_started.connect(_on_dash_started)
	EventBus.player_state_changed.connect(_on_state_changed)
	EventBus.monster_alerted.connect(_on_monster_alerted)

func _process(_delta: float) -> void:
	if player == null or status_label == null:
		return
	var weapon_name := "无"
	if not player.weapons.is_empty():
		weapon_name = player.weapons[player.current_weapon_index].weapon_name
	status_label.text = "阶段 1：Player 原型\n移动：WASD / 方向键\n冲刺：Shift\n射击：鼠标左键\n切换武器：1/2 或鼠标滚轮\n\n状态：%s\n武器：%s\n坐标：%s" % [
		$Player/StateMachine.current_state.name if $Player/StateMachine.current_state else "初始化中",
		weapon_name,
		player.global_position.round(),
	]
	event_label.text = "最近事件：" + _last_event

func _on_weapon_switched(slot_index: int, weapon_data: WeaponData) -> void:
	_last_event = "切换武器 #%d：%s" % [slot_index + 1, weapon_data.weapon_name]

func _on_shot_fired(weapon_data: WeaponData, _position: Vector2, direction: Vector2) -> void:
	_last_event = "开火：%s，方向 %s，噪声 %d" % [weapon_data.weapon_name, direction.round(), weapon_data.noise]

func _on_dash_started(_position: Vector2, direction: Vector2) -> void:
	_last_event = "冲刺：方向 %s" % direction.round()

func _on_state_changed(_previous_state: String, next_state: String) -> void:
	_last_event = "状态切换：" + next_state

func _on_monster_alerted(monster: Node2D, _source: Vector2) -> void:
	_last_event = "怪物警觉：" + monster.name
