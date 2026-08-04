class_name MainMenuUI
extends Control

## 成品主菜单：以概念图中的监狱门禁终端为视觉叙事，不依赖外部 UI 贴图。
## 背景只提供场景氛围；按钮、任务条和设置抽屉是可复用的独立组件。

const INK: Color = Color("E1E4D8")
const MUTED: Color = Color("8F9A91")
const STEEL: Color = Color("1B2528")
const STEEL_LIGHT: Color = Color("344143")
const BLACK: Color = Color("070B0D")
const PANEL: Color = Color("0D1416")
const TEAL: Color = Color("62B9A5")
const AMBER: Color = Color("D49A45")
const RED: Color = Color("B84D45")

var _start_button: Button
var _settings_button: Button
var _quit_button: Button
var _settings_panel: Panel
var _settings_open: bool = false
var _layout_size: Vector2 = Vector2.ZERO
var _ambient_time: float = 0.0
var _button_base_positions: Dictionary = {}
var _warning_light: ColorRect
var _settings_close_button: Button
var _transitioning: bool = false
var _last_focus: Control

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_STOP
	_build_components()
	_layout_components()
	call_deferred("_layout_components")
	visible = true
	_start_button.grab_focus()
	_play_intro()
	queue_redraw()

func _notification(what: int) -> void:
	if what == NOTIFICATION_RESIZED and _start_button != null and size != _layout_size:
		_layout_components()
		queue_redraw()

func _process(delta: float) -> void:
	_ambient_time += delta
	if _warning_light != null:
		var pulse: float = 0.58 + sin(_ambient_time * 1.35) * 0.14
		_warning_light.modulate.a = pulse
	queue_redraw()

func _build_components() -> void:
	var facility: Label = _label("FACILITY 07  /  CELL BLOCK A2", 11, TEAL)
	facility.name = "FacilityLabel"
	add_child(facility)

	var title: Label = _label("PRISON", 62, INK)
	title.name = "Title"
	title.add_theme_color_override("font_shadow_color", Color(0.0, 0.0, 0.0, 0.95))
	title.add_theme_constant_override("shadow_offset_x", 3)
	title.add_theme_constant_override("shadow_offset_y", 3)
	add_child(title)

	var subtitle: Label = _label("SILENT ESCAPE", 15, TEAL)
	subtitle.name = "Subtitle"
	subtitle.add_theme_constant_override("outline_size", 2)
	subtitle.add_theme_color_override("font_outline_color", Color(BLACK, 0.95))
	add_child(subtitle)

	var descriptor: Label = _label("一场低照度设施内的单人撤离行动", 13, MUTED)
	descriptor.name = "Descriptor"
	add_child(descriptor)

	var action_eyebrow: Label = _label("门禁终端  /  等待授权", 11, MUTED)
	action_eyebrow.name = "ActionEyebrow"
	add_child(action_eyebrow)

	var action_panel: Panel = Panel.new()
	action_panel.name = "ActionPanel"
	action_panel.add_theme_stylebox_override("panel", _panel_style(STEEL_LIGHT, 0.76, 1))
	add_child(action_panel)

	_start_button = _make_button("▶   开始任务", TEAL, true)
	_start_button.name = "StartButton"
	_start_button.pressed.connect(_on_start_pressed)
	action_panel.add_child(_start_button)

	_settings_button = _make_button("⚙   设置", AMBER, false)
	_settings_button.name = "SettingsButton"
	_settings_button.pressed.connect(_on_settings_pressed)
	action_panel.add_child(_settings_button)

	_quit_button = _make_button("×   退出", MUTED, false)
	_quit_button.name = "QuitButton"
	_quit_button.pressed.connect(_on_quit_pressed)
	action_panel.add_child(_quit_button)

	var mission_panel: Panel = Panel.new()
	mission_panel.name = "MissionStrip"
	mission_panel.add_theme_stylebox_override("panel", _panel_style(AMBER, 0.86, 2))
	add_child(mission_panel)

	var mission_kicker: Label = _label("当前任务", 11, AMBER)
	mission_kicker.position = Vector2(18.0, 13.0)
	mission_kicker.size = Vector2(100.0, 20.0)
	mission_panel.add_child(mission_kicker)
	var mission_text: Label = _label("恢复电源 03  ·  获取通行证  ·  抵达撤离口", 14, INK)
	mission_text.position = Vector2(18.0, 36.0)
	mission_text.size = Vector2(480.0, 24.0)
	mission_panel.add_child(mission_text)
	var mission_state: Label = _label("未开始", 11, MUTED)
	mission_state.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	mission_state.position = Vector2(430.0, 18.0)
	mission_state.size = Vector2(102.0, 28.0)
	mission_panel.add_child(mission_state)

	var hint: Label = _label("WASD 移动   鼠标瞄准   Tab 背包   E 交互", 11, MUTED)
	hint.name = "InputHint"
	add_child(hint)

	var version: Label = _label("SURVIVOR PROTOCOL  /  DEMO 01", 10, Color(MUTED, 0.72))
	version.name = "VersionLabel"
	version.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	add_child(version)

	_warning_light = ColorRect.new()
	_warning_light.name = "WarningLight"
	_warning_light.color = RED
	_warning_light.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_warning_light)

	_settings_panel = _build_settings_panel()
	add_child(_settings_panel)

func _build_settings_panel() -> Panel:
	var panel: Panel = Panel.new()
	panel.name = "SettingsDrawer"
	panel.visible = false
	panel.modulate.a = 0.0
	panel.mouse_filter = Control.MOUSE_FILTER_STOP
	panel.add_theme_stylebox_override("panel", _panel_style(AMBER, 0.98, 2))

	var title: Label = _label("终端设置", 22, INK)
	title.position = Vector2(24.0, 22.0)
	title.size = Vector2(270.0, 30.0)
	panel.add_child(title)
	var caption: Label = _label("本次演示的运行配置", 11, MUTED)
	caption.position = Vector2(24.0, 56.0)
	caption.size = Vector2(270.0, 20.0)
	panel.add_child(caption)

	var resolution: Label = _label("画面\n1280 × 720", 13, INK)
	resolution.position = Vector2(24.0, 96.0)
	resolution.size = Vector2(150.0, 48.0)
	panel.add_child(resolution)
	var resolution_state: Label = _label("已锁定", 11, TEAL)
	resolution_state.position = Vector2(194.0, 104.0)
	resolution_state.size = Vector2(72.0, 24.0)
	resolution_state.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	panel.add_child(resolution_state)

	var audio: Label = _label("声音\n默认混音", 13, INK)
	audio.position = Vector2(24.0, 158.0)
	audio.size = Vector2(150.0, 48.0)
	panel.add_child(audio)
	var audio_state: Label = _label("开启", 11, TEAL)
	audio_state.position = Vector2(194.0, 166.0)
	audio_state.size = Vector2(72.0, 24.0)
	audio_state.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	panel.add_child(audio_state)

	_settings_close_button = _make_button("返回终端", AMBER, false)
	_settings_close_button.position = Vector2(24.0, 228.0)
	_settings_close_button.size = Vector2(252.0, 42.0)
	_settings_close_button.pressed.connect(_on_settings_pressed)
	panel.add_child(_settings_close_button)
	return panel

func _layout_components() -> void:
	_layout_size = size
	var narrow: bool = size.x < 900.0
	var left: float = 42.0 if narrow else 78.0
	var action_width: float = 300.0 if not narrow else minf(300.0, size.x - 84.0)

	_set_rect("FacilityLabel", Vector2(left, 42.0), Vector2(440.0, 20.0))
	_set_rect("Title", Vector2(left - 4.0, 66.0), Vector2(460.0, 78.0))
	_set_rect("Subtitle", Vector2(left + 2.0, 142.0), Vector2(260.0, 24.0))
	_set_rect("Descriptor", Vector2(left + 2.0, 171.0), Vector2(360.0, 22.0))
	_set_rect("ActionEyebrow", Vector2(left + 18.0, 226.0), Vector2(action_width - 36.0, 20.0))

	var action_panel: Panel = get_node("ActionPanel") as Panel
	action_panel.position = Vector2(left, 250.0)
	action_panel.size = Vector2(action_width, 136.0)
	_start_button.position = Vector2(18.0, 16.0)
	_start_button.size = Vector2(action_width - 36.0, 46.0)
	_settings_button.position = Vector2(18.0, 74.0)
	_settings_button.size = Vector2((action_width - 44.0) * 0.5, 38.0)
	_quit_button.position = Vector2(26.0 + (action_width - 44.0) * 0.5, 74.0)
	_quit_button.size = Vector2((action_width - 44.0) * 0.5, 38.0)
	_button_base_positions[_start_button] = _start_button.position
	_button_base_positions[_settings_button] = _settings_button.position
	_button_base_positions[_quit_button] = _quit_button.position

	var mission: Panel = get_node("MissionStrip") as Panel
	var rail_bottom: float = minf(size.y - 88.0, 468.0)
	mission.position = Vector2(left, rail_bottom - 72.0)
	mission.size = Vector2(560.0 if not narrow else size.x - left * 2.0, 72.0)
	_set_rect("InputHint", Vector2(left, rail_bottom + 12.0), Vector2(480.0, 18.0))
	_set_rect("VersionLabel", Vector2(size.x - left - 300.0, rail_bottom + 12.0), Vector2(300.0, 18.0))
	_warning_light.position = Vector2(size.x - left - 14.0, 42.0)
	_warning_light.size = Vector2(8.0, 8.0)

	var drawer_width: float = 320.0 if size.x >= 700.0 else size.x - 48.0
	_settings_panel.position = Vector2(size.x - drawer_width - left, 72.0)
	_settings_panel.size = Vector2(drawer_width, 294.0)

func _set_rect(node_name: String, position: Vector2, node_size: Vector2) -> void:
	var node: Control = get_node_or_null(NodePath(node_name)) as Control
	if node == null:
		return
	node.position = position
	node.size = node_size

func _label(text_value: String, font_size: int, color: Color) -> Label:
	var label: Label = Label.new()
	label.text = text_value
	label.add_theme_font_size_override("font_size", font_size)
	label.add_theme_color_override("font_color", color)
	label.add_theme_color_override("font_shadow_color", Color(0.0, 0.0, 0.0, 0.78))
	label.add_theme_constant_override("shadow_offset_x", 1)
	label.add_theme_constant_override("shadow_offset_y", 1)
	label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return label

func _make_button(text_value: String, accent: Color, primary: bool) -> Button:
	var button: Button = Button.new()
	button.text = text_value
	button.add_theme_font_size_override("font_size", 16 if primary else 13)
	button.add_theme_color_override("font_color", INK)
	button.add_theme_color_override("font_hover_color", Color.WHITE)
	button.add_theme_color_override("font_pressed_color", Color.WHITE)
	button.add_theme_color_override("font_focus_color", INK)
	button.add_theme_stylebox_override("normal", _button_style(accent, 0.12, primary))
	button.add_theme_stylebox_override("hover", _button_style(accent, 0.27, primary))
	button.add_theme_stylebox_override("pressed", _button_style(accent, 0.42, primary))
	button.add_theme_stylebox_override("focus", _button_style(accent, 0.22, primary))
	button.add_theme_stylebox_override("disabled", _button_style(Color(STEEL_LIGHT, 0.7), 0.05, false))
	button.focus_mode = Control.FOCUS_ALL
	button.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	button.mouse_entered.connect(_on_button_hover.bind(button, true))
	button.mouse_exited.connect(_on_button_hover.bind(button, false))
	button.focus_entered.connect(_on_button_focus.bind(button, true))
	button.focus_exited.connect(_on_button_focus.bind(button, false))
	button.pressed.connect(_on_button_pressed.bind(button))
	return button

func _button_style(accent: Color, fill_alpha: float, primary: bool) -> StyleBoxFlat:
	var style: StyleBoxFlat = StyleBoxFlat.new()
	style.bg_color = Color(accent, fill_alpha)
	style.border_color = Color(accent, 0.9 if primary else 0.58)
	style.set_border_width_all(1)
	style.border_width_left = 3 if primary else 1
	style.corner_radius_top_left = 2
	style.corner_radius_top_right = 2
	style.corner_radius_bottom_left = 2
	style.corner_radius_bottom_right = 2
	style.content_margin_left = 18.0
	style.content_margin_right = 18.0
	return style

func _panel_style(accent: Color, alpha: float, border_width: int) -> StyleBoxFlat:
	var style: StyleBoxFlat = StyleBoxFlat.new()
	style.bg_color = Color(PANEL, alpha)
	style.border_color = Color(accent, 0.64)
	style.set_border_width_all(border_width)
	style.corner_radius_top_left = 2
	style.corner_radius_top_right = 2
	style.corner_radius_bottom_left = 2
	style.corner_radius_bottom_right = 2
	style.shadow_color = Color(0.0, 0.0, 0.0, 0.72)
	style.shadow_size = 16
	return style

func _on_button_hover(button: Button, hovered: bool) -> void:
	if button == null:
		return
	_animate_button(button, hovered)

func _on_button_focus(button: Button, focused: bool) -> void:
	if button == null or button == _start_button:
		return
	_animate_button(button, focused)

func _on_button_pressed(button: Button) -> void:
	if button == null:
		return
	var base: Vector2 = _button_base_positions.get(button, button.position)
	var tween: Tween = create_tween()
	tween.tween_property(button, "position", base + Vector2(2.0, 1.0), 0.06)
	tween.tween_property(button, "position", base, 0.16)

func _animate_button(button: Button, active: bool) -> void:
	var base: Vector2 = _button_base_positions.get(button, button.position)
	var target: Vector2 = base + Vector2(5.0, 0.0) if active else base
	var tween: Tween = create_tween()
	tween.set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	tween.tween_property(button, "position", target, 0.12)

func _play_intro() -> void:
	for node_name in ["FacilityLabel", "Title", "Subtitle", "Descriptor", "ActionEyebrow", "ActionPanel", "MissionStrip", "InputHint", "VersionLabel"]:
		var node: Control = get_node_or_null(NodePath(node_name)) as Control
		if node == null:
			continue
		node.modulate.a = 0.0
		var delay: float = 0.04 * float(["FacilityLabel", "Title", "Subtitle", "Descriptor", "ActionEyebrow", "ActionPanel", "MissionStrip", "InputHint", "VersionLabel"].find(node_name))
		var tween: Tween = create_tween()
		tween.tween_interval(delay)
		tween.tween_property(node, "modulate:a", 1.0, 0.28)

func _on_start_pressed() -> void:
	if _transitioning:
		return
	_transitioning = true
	_set_main_buttons_enabled(false)
	visible = false
	EventBus.run_start_requested.emit()

func _on_settings_pressed() -> void:
	if _transitioning:
		return
	_settings_open = not _settings_open
	if _settings_open:
		_last_focus = get_viewport().gui_get_focus_owner()
		_set_main_buttons_enabled(false)
		_settings_panel.visible = true
		_settings_panel.position.x += 24.0
		var show_tween: Tween = create_tween()
		show_tween.set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
		show_tween.parallel().tween_property(_settings_panel, "position:x", _settings_panel.position.x - 24.0, 0.22)
		show_tween.parallel().tween_property(_settings_panel, "modulate:a", 1.0, 0.22)
		show_tween.tween_callback(_settings_close_button.grab_focus)
	else:
		var hide_tween: Tween = create_tween()
		hide_tween.set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
		hide_tween.parallel().tween_property(_settings_panel, "position:x", _settings_panel.position.x + 24.0, 0.16)
		hide_tween.parallel().tween_property(_settings_panel, "modulate:a", 0.0, 0.16)
		hide_tween.tween_callback(_settings_panel.hide)
		hide_tween.tween_callback(_restore_menu_focus)
		_set_main_buttons_enabled(true)

func _on_quit_pressed() -> void:
	get_tree().quit()

func _set_main_buttons_enabled(enabled: bool) -> void:
	if _start_button != null:
		_start_button.disabled = not enabled
	if _settings_button != null:
		_settings_button.disabled = not enabled
	if _quit_button != null:
		_quit_button.disabled = not enabled

func _restore_menu_focus() -> void:
	if _last_focus != null and is_instance_valid(_last_focus) and _last_focus != _settings_close_button:
		_last_focus.grab_focus()
	else:
		_start_button.grab_focus()

func _unhandled_input(event: InputEvent) -> void:
	if not visible:
		return
	if event.is_action_pressed("ui_cancel") and _settings_open:
		_on_settings_pressed()
		get_viewport().set_input_as_handled()

func _draw() -> void:
	var screen: Vector2 = size
	draw_rect(Rect2(Vector2.ZERO, screen), BLACK, true)
	_draw_prison_scene(screen)
	_draw_terminal_shade(screen)

func _draw_prison_scene(screen: Vector2) -> void:
	var scene_left: float = screen.x * 0.40
	var scene_rect: Rect2 = Rect2(scene_left, 0.0, screen.x - scene_left, screen.y)
	draw_rect(scene_rect, Color("0D1517"), true)
	# 后墙：窄而克制的建筑层，不用满屏网格。
	for index in range(5):
		var x: float = scene_left + 48.0 + float(index) * 110.0
		draw_rect(Rect2(x, 62.0, 74.0, screen.y * 0.58), Color("111C1E"), true)
		draw_line(Vector2(x, 62.0), Vector2(x, screen.y * 0.64), Color(STEEL_LIGHT, 0.22), 2.0)
		draw_line(Vector2(x + 74.0, 62.0), Vector2(x + 74.0, screen.y * 0.64), Color(BLACK, 0.7), 3.0)
	# 中央铁门和栏杆，作为标题右侧的明确剪影。
	var gate: Rect2 = Rect2(scene_left + 86.0, 122.0, 214.0, 246.0)
	draw_rect(gate, Color("080D0E"), true)
	draw_rect(Rect2(gate.position, Vector2(gate.size.x, 8.0)), Color(STEEL_LIGHT, 0.82), true)
	for index in range(8):
		var bar_x: float = gate.position.x + 16.0 + float(index) * 26.0
		draw_rect(Rect2(bar_x, gate.position.y + 13.0, 7.0, gate.size.y - 26.0), Color("2D3738"), true)
		draw_line(Vector2(bar_x + 1.0, gate.position.y + 14.0), Vector2(bar_x + 1.0, gate.end.y - 14.0), Color("56605D", 0.34), 1.0)
	draw_rect(Rect2(gate.position.x + 78.0, gate.end.y - 38.0, 62.0, 4.0), Color(AMBER, 0.38), true)
	# 地面平台与冷暖局部照明。
	draw_rect(Rect2(scene_left, 420.0, screen.x - scene_left, screen.y - 420.0), Color("0A1112"), true)
	draw_line(Vector2(scene_left, 420.0), Vector2(screen.x, 420.0), Color(STEEL_LIGHT, 0.45), 3.0)
	draw_circle(Vector2(scene_left + 260.0, 390.0), 145.0, Color(0.05, 0.48, 0.42, 0.09))
	draw_circle(Vector2(screen.x - 100.0, 250.0), 120.0, Color(0.58, 0.18, 0.10, 0.075))
	# 电源节点：青色的场景锚点。
	var power: Vector2 = Vector2(scene_left + 260.0, 300.0)
	draw_circle(power, 48.0, Color(0.10, 0.76, 0.66, 0.10))
	draw_circle(power, 26.0, Color("102B2C"))
	draw_circle(power, 17.0, Color(TEAL, 0.78))
	draw_circle(power, 8.0, Color("B4E6D0"))
	draw_line(power + Vector2(-32.0, 0.0), power + Vector2(32.0, 0.0), Color(TEAL, 0.38), 1.0)
	draw_line(power + Vector2(0.0, -32.0), power + Vector2(0.0, 32.0), Color(TEAL, 0.28), 1.0)

func _draw_terminal_shade(screen: Vector2) -> void:
	# 左侧遮罩压低场景细节，让菜单信息清晰但仍能看见监狱材质。
	var left_width: float = minf(screen.x * 0.56, 690.0)
	draw_rect(Rect2(0.0, 0.0, left_width, screen.y), Color(0.015, 0.024, 0.025, 0.72), true)
	draw_rect(Rect2(0.0, 0.0, screen.x, 18.0), Color(BLACK, 0.42), true)
	draw_rect(Rect2(0.0, screen.y - 22.0, screen.x, 22.0), Color(BLACK, 0.52), true)
	# 单一的细钢板边缘，替代原先铺满屏幕的装饰线。
	draw_line(Vector2(22.0, 22.0), Vector2(screen.x - 22.0, 22.0), Color(STEEL_LIGHT, 0.52), 1.0)
	draw_line(Vector2(22.0, 22.0), Vector2(22.0, screen.y - 30.0), Color(STEEL_LIGHT, 0.34), 1.0)
	for index in range(4):
		var mark_x: float = screen.x - 128.0 + float(index) * 14.0
		draw_rect(Rect2(mark_x, 28.0, 7.0, 3.0), Color(TEAL, 0.30 if index > 1 else 0.72), true)
