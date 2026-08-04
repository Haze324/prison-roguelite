@tool
class_name Merchant
extends Node2D

signal interaction_requested(merchant: Node2D)

const PORTRAIT_TEXTURE: Texture2D = preload("res://assets/俯视角/The Female Adventurer - Free/The Female Adventurer - Free/Idle/Idle.png")

@export var portrait_frame: int = 1
@export var portrait_scale: float = 1.25
@export var invulnerable: bool = true ## 商人是功能型 NPC，不参与伤害与战斗。
@export var interaction_radius: float = 58.0

var player: Player
var _portrait: Sprite2D
var _player_nearby: bool = false

func _ready() -> void:
	add_to_group("friendly_npcs")
	_ensure_portrait()
	queue_redraw()

func setup(target: Player) -> void:
	player = target
	queue_redraw()

func _process(_delta: float) -> void:
	if not Engine.is_editor_hint() and player != null:
		var nearby: bool = is_instance_valid(player) and global_position.distance_to(player.global_position) <= interaction_radius
		if nearby != _player_nearby:
			_player_nearby = nearby
			queue_redraw()
		if nearby and Input.is_action_just_pressed("interact"):
			interaction_requested.emit(self)

func buy_item(item_key: String) -> bool:
	if player == null:
		return false
	var price: int = 15
	if item_key == "ammo_box":
		price = 10
	elif item_key == "adrenaline":
		price = 18
	if MetaProgression.coins < price:
		EventBus.consumable_used.emit("商人：硬币不足")
		return false
	if item_key == "medkit":
		if player.medkits >= player.get_medkit_maximum():
			EventBus.consumable_used.emit("商人：医疗包已满")
			return false
		player.medkits += 1
	elif item_key == "ammo_box" or item_key == "adrenaline":
		player.consumable_counts[item_key] = int(player.consumable_counts.get(item_key, 0)) + 1
	else:
		return false
	MetaProgression.add_coins(-price)
	EventBus.consumable_used.emit("商人：已购买 " + item_key)
	return true

func _ensure_portrait() -> void:
	if _portrait == null:
		_portrait = Sprite2D.new()
		_portrait.name = "MerchantPortrait"
		add_child(_portrait)
	_portrait.texture = PORTRAIT_TEXTURE
	_portrait.hframes = 8
	_portrait.vframes = 6
	_portrait.frame = clampi(portrait_frame, 0, 47)
	_portrait.scale = Vector2.ONE * portrait_scale

func _draw() -> void:
	# No HP/progress bar: the portrait is the merchant's identity and the prompt is contextual.
	if _player_nearby or Engine.is_editor_hint():
		draw_string(ThemeDB.fallback_font, Vector2(-34.0, -58.0), "商人", HORIZONTAL_ALIGNMENT_LEFT, -1.0, 11, Color("72E0C2"))
		draw_string(ThemeDB.fallback_font, Vector2(-48.0, 56.0), "E：交谈", HORIZONTAL_ALIGNMENT_LEFT, -1.0, 10, Color("E8F0E9"))
