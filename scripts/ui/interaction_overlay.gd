class_name InteractionOverlay
extends Control

## 对话和商店覆盖层。保留主流程使用的公开方法与 dialogue_finished 信号。
## 视觉使用原生绘制，避免把 Paper UI 素材耦合进交互逻辑。

signal dialogue_finished(dialogue_kind: String, target: Node)

const BG: Color = Color("050A0D")
const PANEL: Color = Color("0C181E")
const PANEL_ALT: Color = Color("12252B")
const INK: Color = Color("E7F1ED")
const MUTED: Color = Color("91A7A1")
const MINT: Color = Color("61E4C0")
const AMBER: Color = Color("E7B455")
const RED: Color = Color("E56568")

const SHOP_ITEMS: Array[Dictionary] = [
	{"key": "medkit", "name": "医疗包", "desc": "恢复生命值", "price": 15, "accent": RED},
	{"key": "ammo_box", "name": "弹药箱", "desc": "补充弹药资源", "price": 10, "accent": MINT},
	{"key": "adrenaline", "name": "肾上腺素", "desc": "短时间强化行动", "price": 18, "accent": AMBER},
]

var mode: String = "hidden"
var dialogue_kind: String = ""
var dialogue_target: Node
var dialogue_lines: Array[Dictionary] = []
var dialogue_index: int = 0
var portrait: Texture2D
var portrait_frame: int = 0
var portrait_columns: int = 8
var portrait_rows: int = 6
var shop_target: Merchant
var shop_message: String = ""

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	mouse_filter = Control.MOUSE_FILTER_STOP
	visible = false
	set_process_input(true)

func open_corpse_dialogue(target: Node, corpse_portrait: Texture2D, corpse_frame: int) -> void:
	dialogue_kind = "corpse"
	dialogue_target = target
	dialogue_lines = [
		{"speaker": "旁白", "text": "尸体的外套已经被血浸透。你伸手检查他的口袋。"},
		{"speaker": "旁白", "text": "你找到一张通信证，芯片仍在微弱地闪烁。"},
		{"speaker": "旁白", "text": "远处传来警报。这里发生过撤离，也发生过背叛。"},
		{"speaker": "旁白", "text": "通信证或许能让你通过某些封锁门。先活着离开这里。"},
	]
	_open_dialogue(corpse_portrait, corpse_frame)

func open_merchant_dialogue(target: Merchant) -> void:
	dialogue_kind = "merchant"
	dialogue_target = target
	dialogue_lines = [{"speaker": "商人", "text": "别站在门口发呆。需要补给，就趁现在。"}]
	_open_dialogue(Merchant.PORTRAIT_TEXTURE, target.portrait_frame)

func _open_dialogue(texture: Texture2D, frame: int) -> void:
	portrait = texture
	portrait_frame = frame
	dialogue_index = 0
	mode = "dialogue"
	visible = true
	get_tree().paused = true
	queue_redraw()

func open_shop(target: Merchant) -> void:
	shop_target = target
	shop_message = ""
	mode = "shop"
	visible = true
	get_tree().paused = true
	queue_redraw()

func close_overlay() -> void:
	mode = "hidden"
	visible = false
	shop_target = null
	get_tree().paused = false
	queue_redraw()

func _input(event: InputEvent) -> void:
	if mode == "hidden":
		return
	if event is InputEventKey and event.is_pressed() and not event.is_echo():
		var key_event: InputEventKey = event as InputEventKey
		if key_event.physical_keycode == KEY_ESCAPE:
			close_overlay()
			get_viewport().set_input_as_handled()
			return
		if key_event.physical_keycode == KEY_E or key_event.physical_keycode == KEY_ENTER or key_event.physical_keycode == KEY_SPACE:
			_advance()
			get_viewport().set_input_as_handled()
			return
	if event is InputEventMouseButton and event.is_pressed() and (event as InputEventMouseButton).button_index == MOUSE_BUTTON_LEFT:
		if mode == "dialogue":
			_advance()
		else:
			_handle_shop_click((event as InputEventMouseButton).position)
		get_viewport().set_input_as_handled()

func _advance() -> void:
	if mode == "shop":
		return
	if dialogue_index < dialogue_lines.size() - 1:
		dialogue_index += 1
		queue_redraw()
		return
	if dialogue_kind == "merchant" and dialogue_target is Merchant:
		open_shop(dialogue_target as Merchant)
		return
	var finished_kind: String = dialogue_kind
	var finished_target: Node = dialogue_target
	close_overlay()
	dialogue_finished.emit(finished_kind, finished_target)

func _handle_shop_click(mouse_position: Vector2) -> void:
	if shop_target == null:
		return
	var panel: Rect2 = _shop_panel(get_viewport_rect().size)
	for index in SHOP_ITEMS.size():
		var card: Rect2 = Rect2(panel.position + Vector2(28.0, 96.0 + float(index) * 94.0), Vector2(panel.size.x - 56.0, 76.0))
		if card.has_point(mouse_position):
			if shop_target.buy_item(String(SHOP_ITEMS[index].key)):
				shop_message = "购买成功"
			else:
				shop_message = "硬币不足"
			queue_redraw()
			return

func _draw() -> void:
	if mode == "hidden":
		return
	var screen: Vector2 = get_viewport_rect().size
	draw_rect(Rect2(Vector2.ZERO, screen), Color(BG, 0.82), true)
	_draw_grid(screen)
	if mode == "dialogue":
		_draw_dialogue(screen)
	elif mode == "shop":
		_draw_shop(screen)

func _draw_dialogue(screen: Vector2) -> void:
	var panel: Rect2 = Rect2(44.0, screen.y - 226.0, screen.x - 88.0, 174.0)
	_draw_frame(panel, MINT)
	var portrait_rect: Rect2 = Rect2(panel.position + Vector2(18.0, 18.0), Vector2(132.0, 132.0))
	draw_rect(portrait_rect, Color("071014"), true)
	draw_rect(portrait_rect, AMBER if dialogue_kind == "corpse" else MINT, false, 2.0)
	_draw_portrait(portrait_rect)
	var line: Dictionary = dialogue_lines[dialogue_index]
	var accent: Color = AMBER if dialogue_kind == "corpse" else MINT
	draw_string(ThemeDB.fallback_font, panel.position + Vector2(174.0, 43.0), str(line.speaker), HORIZONTAL_ALIGNMENT_LEFT, -1.0, 16, accent)
	draw_multiline_string(ThemeDB.fallback_font, panel.position + Vector2(174.0, 82.0), str(line.text), HORIZONTAL_ALIGNMENT_LEFT, panel.size.x - 230.0, 19, 16, INK)
	draw_string(ThemeDB.fallback_font, panel.position + Vector2(panel.size.x - 224.0, panel.size.y - 20.0), "E / Enter / 鼠标继续", HORIZONTAL_ALIGNMENT_LEFT, -1.0, 11, MUTED)
	draw_string(ThemeDB.fallback_font, panel.position + Vector2(20.0, panel.size.y - 20.0), "%d / %d" % [dialogue_index + 1, dialogue_lines.size()], HORIZONTAL_ALIGNMENT_LEFT, -1.0, 11, MUTED)

func _draw_shop(screen: Vector2) -> void:
	var panel: Rect2 = _shop_panel(screen)
	_draw_frame(panel, MINT)
	draw_string(ThemeDB.fallback_font, panel.position + Vector2(28.0, 38.0), "补给商店", HORIZONTAL_ALIGNMENT_LEFT, -1.0, 23, INK)
	draw_string(ThemeDB.fallback_font, panel.position + Vector2(28.0, 66.0), "硬币：%d" % MetaProgression.coins, HORIZONTAL_ALIGNMENT_LEFT, -1.0, 13, AMBER)
	for index in SHOP_ITEMS.size():
		var item: Dictionary = SHOP_ITEMS[index]
		var card: Rect2 = Rect2(panel.position + Vector2(28.0, 96.0 + float(index) * 94.0), Vector2(panel.size.x - 56.0, 76.0))
		var accent: Color = item.accent as Color
		draw_rect(card, Color(PANEL_ALT, 0.98), true)
		draw_rect(card, Color(accent, 0.72), false, 1.0)
		draw_circle(card.position + Vector2(34.0, 38.0), 12.0, Color(accent, 0.18))
		draw_circle(card.position + Vector2(34.0, 38.0), 5.0, accent)
		draw_string(ThemeDB.fallback_font, card.position + Vector2(62.0, 31.0), str(item.name), HORIZONTAL_ALIGNMENT_LEFT, -1.0, 16, INK)
		draw_string(ThemeDB.fallback_font, card.position + Vector2(62.0, 55.0), str(item.desc), HORIZONTAL_ALIGNMENT_LEFT, -1.0, 12, MUTED)
		draw_string(ThemeDB.fallback_font, card.position + Vector2(card.size.x - 90.0, 44.0), "%d 硬币" % int(item.price), HORIZONTAL_ALIGNMENT_LEFT, -1.0, 13, AMBER)
	if shop_message != "":
		draw_string(ThemeDB.fallback_font, panel.position + Vector2(28.0, panel.size.y - 22.0), shop_message, HORIZONTAL_ALIGNMENT_LEFT, -1.0, 12, MINT)
	draw_string(ThemeDB.fallback_font, panel.position + Vector2(panel.size.x - 132.0, panel.size.y - 22.0), "Esc 关闭", HORIZONTAL_ALIGNMENT_LEFT, -1.0, 11, MUTED)

func _shop_panel(screen: Vector2) -> Rect2:
	var panel_size: Vector2 = Vector2(minf(720.0, screen.x - 72.0), 500.0)
	return Rect2(screen * 0.5 - panel_size * 0.5, panel_size)

func _draw_portrait(target_rect: Rect2) -> void:
	if portrait == null:
		return
	var frame_width: float = float(portrait.get_width()) / float(portrait_columns)
	var frame_height: float = float(portrait.get_height()) / float(portrait_rows)
	var frame_index: int = clampi(portrait_frame, 0, portrait_columns * portrait_rows - 1)
	var source: Rect2 = Rect2(float(frame_index % portrait_columns) * frame_width, float(frame_index / portrait_columns) * frame_height, frame_width, frame_height)
	draw_texture_rect_region(portrait, target_rect.grow(-8.0), source)

func _draw_grid(screen: Vector2) -> void:
	for x in range(0, int(screen.x) + 1, 48):
		draw_line(Vector2(x, 0.0), Vector2(x, screen.y), Color(MINT, 0.035), 1.0)
	for y in range(0, int(screen.y) + 1, 48):
		draw_line(Vector2(0.0, y), Vector2(screen.x, y), Color(MINT, 0.035), 1.0)

func _draw_frame(rect: Rect2, accent: Color) -> void:
	draw_rect(rect.grow(6.0), Color(0.0, 0.0, 0.0, 0.45), true)
	draw_rect(rect, Color(PANEL, 0.98), true)
	draw_rect(rect, Color(accent, 0.9), false, 1.0)
	draw_rect(rect.grow(-6.0), Color(accent, 0.24), false, 1.0)
	var length: float = 26.0
	draw_line(rect.position + Vector2(0.0, 9.0), rect.position + Vector2(length, 9.0), accent, 2.0)
	draw_line(rect.position + Vector2(9.0, 0.0), rect.position + Vector2(9.0, length), accent, 2.0)
	draw_line(Vector2(rect.end.x - length, rect.position.y + 9.0), Vector2(rect.end.x - 9.0, rect.position.y + 9.0), accent, 2.0)
	draw_line(Vector2(rect.end.x - 9.0, rect.end.y - length), Vector2(rect.end.x - 9.0, rect.end.y - 9.0), accent, 2.0)
