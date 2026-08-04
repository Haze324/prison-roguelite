class_name MainMenuUI
extends Control

## 主菜单：使用 Godot 原生矢量绘制和 StyleBox，不依赖 Paper UI 素材。
## 这个节点只负责菜单呈现与输入，开始任务仍通过 EventBus 交给主流程。

const INK: Color = Color("E7F1ED")
const MUTED: Color = Color("91A7A1")
const MINT: Color = Color("61E4C0")
const AMBER: Color = Color("E7B455")
const RED: Color = Color("E56568")
const PANEL: Color = Color("0B151A")
const PANEL_ALT: Color = Color("101F25")

var _start_button: Button
var _settings_button: Button
var _quit_button: Button
var _settings_panel: Panel
var _settings_open: bool = false
var _layout_size: Vector2 = Vector2.ZERO

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_STOP
	_build_components()
	_layout_components()
	visible = true
	queue_redraw()

func _notification(what: int) -> void:
	if what == NOTIFICATION_RESIZED and _start_button != null and size != _layout_size:
		_layout_components()
		queue_redraw()

func _build_components() -> void:
	var eyebrow: Label = _label("FACILITY 07  //  NIGHT SHIFT", 12, MINT)
	eyebrow.name = "Eyebrow"
	add_child(eyebrow)

	var title: Label = _label("PRISON", 58, INK)
	title.name = "Title"
	add_child(title)

	var subtitle: Label = _label("SILENT ESCAPE", 17, AMBER)
	subtitle.name = "Subtitle"
	add_child(subtitle)

	var descriptor: Label = _label("横板潜入 · 低照度设施 · 单人撤离", 13, MUTED)
	descriptor.name = "Descriptor"
	add_child(descriptor)

	var mission_panel: Panel = Panel.new()
	mission_panel.name = "MissionBrief"
	mission_panel.add_theme_stylebox_override("panel", _panel_style(MINT, 0.92))
	add_child(mission_panel)
	var mission_title: Label = _label("任务简报", 15, MINT)
	mission_title.position = Vector2(24.0, 20.0)
	mission_title.size = Vector2(280.0, 24.0)
	mission_panel.add_child(mission_title)
	var mission_line: ColorRect = ColorRect.new()
	mission_line.position = Vector2(24.0, 54.0)
	mission_line.size = Vector2(280.0, 1.0)
	mission_line.color = Color(MINT, 0.55)
	mission_panel.add_child(mission_line)
	var brief: Label = _label("01  修复三处电源节点\n\n02  控制噪声，避开守卫苏醒\n\n03  获取通行证并抵达撤离口", 14, INK)
	brief.position = Vector2(24.0, 76.0)
	brief.size = Vector2(320.0, 150.0)
	brief.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	mission_panel.add_child(brief)
	var map_hint: Label = _label("CELL BLOCK A2  /  当前调试地图", 11, AMBER)
	map_hint.position = Vector2(24.0, 246.0)
	map_hint.size = Vector2(300.0, 22.0)
	mission_panel.add_child(map_hint)

	var menu_panel: Panel = Panel.new()
	menu_panel.name = "ActionPanel"
	menu_panel.add_theme_stylebox_override("panel", _panel_style(AMBER, 0.95))
	add_child(menu_panel)
	var menu_title: Label = _label("行动协议", 15, AMBER)
	menu_title.position = Vector2(28.0, 24.0)
	menu_title.size = Vector2(300.0, 24.0)
	menu_panel.add_child(menu_title)
	var menu_note: Label = _label("准备进入设施。\n所有输入将在任务开始后恢复。", 13, MUTED)
	menu_note.position = Vector2(28.0, 62.0)
	menu_note.size = Vector2(300.0, 48.0)
	menu_note.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	menu_panel.add_child(menu_note)

	_start_button = _make_button("开始任务", MINT)
	_start_button.name = "StartButton"
	_start_button.pressed.connect(_on_start_pressed)
	menu_panel.add_child(_start_button)
	_settings_button = _make_button("设置", AMBER)
	_settings_button.name = "SettingsButton"
	_settings_button.pressed.connect(_on_settings_pressed)
	menu_panel.add_child(_settings_button)
	_quit_button = _make_button("退出", RED)
	_quit_button.name = "QuitButton"
	_quit_button.pressed.connect(_on_quit_pressed)
	menu_panel.add_child(_quit_button)

	_settings_panel = Panel.new()
	_settings_panel.name = "SettingsPanel"
	_settings_panel.add_theme_stylebox_override("panel", _panel_style(AMBER, 0.98))
	_settings_panel.visible = false
	add_child(_settings_panel)
	var settings_title: Label = _label("设置", 20, INK)
	settings_title.position = Vector2(24.0, 20.0)
	settings_title.size = Vector2(260.0, 28.0)
	_settings_panel.add_child(settings_title)
	var settings_text: Label = _label("分辨率\n1280 × 720\n\n鼠标灵敏度\n默认", 14, MUTED)
	settings_text.position = Vector2(24.0, 64.0)
	settings_text.size = Vector2(260.0, 130.0)
	_settings_panel.add_child(settings_text)

	var footer: Label = _label("WASD 移动   鼠标瞄准   Tab 背包   E 交互   T 手电筒", 12, MUTED)
	footer.name = "Footer"
	add_child(footer)
	var build: Label = _label("SURVIVOR PROTOCOL  //  DEMO", 11, Color(MINT, 0.72))
	build.name = "BuildLabel"
	build.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	add_child(build)

func _layout_components() -> void:
	_layout_size = size
	var narrow: bool = size.x < 920.0
	var left_x: float = 56.0 if narrow else 82.0
	var panel_y: float = 220.0 if not narrow else 180.0
	var mission_width: float = 360.0 if not narrow else minf(size.x - 112.0, 360.0)
	var action_width: float = 360.0 if not narrow else minf(size.x - 112.0, 360.0)
	var action_x: float = size.x - action_width - left_x if not narrow else left_x

	_set_rect("Eyebrow", Vector2(left_x, 42.0), Vector2(420.0, 22.0))
	_set_rect("Title", Vector2(left_x - 4.0, 66.0), Vector2(500.0, 70.0))
	_set_rect("Subtitle", Vector2(left_x + 4.0, 136.0), Vector2(300.0, 28.0))
	_set_rect("Descriptor", Vector2(left_x + 4.0, 166.0), Vector2(360.0, 22.0))

	var mission: Panel = get_node("MissionBrief") as Panel
	mission.position = Vector2(left_x, panel_y)
	mission.size = Vector2(mission_width, 286.0)
	var action: Panel = get_node("ActionPanel") as Panel
	action.position = Vector2(action_x, panel_y - 26.0)
	action.size = Vector2(action_width, 356.0)
	_start_button.size.x = action_width - 56.0
	_settings_button.size.x = action_width - 56.0
	_quit_button.size.x = action_width - 56.0
	_set_rect("Footer", Vector2(left_x, size.y - 46.0), Vector2(600.0, 22.0))
	_set_rect("BuildLabel", Vector2(size.x - 330.0 - left_x, size.y - 46.0), Vector2(330.0, 22.0))
	_settings_panel.position = Vector2(action.position.x - 30.0, action.position.y + 70.0)
	_settings_panel.size = Vector2(300.0, 230.0)

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
	label.add_theme_color_override("font_shadow_color", Color(0.0, 0.0, 0.0, 0.75))
	label.add_theme_constant_override("shadow_offset_x", 1)
	label.add_theme_constant_override("shadow_offset_y", 1)
	label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return label

func _make_button(text_value: String, accent: Color) -> Button:
	var button: Button = Button.new()
	button.text = text_value
	button.position = Vector2(28.0, 124.0)
	button.size = Vector2(304.0, 48.0)
	button.add_theme_font_size_override("font_size", 15)
	button.add_theme_color_override("font_color", INK)
	button.add_theme_color_override("font_hover_color", Color.WHITE)
	button.add_theme_color_override("font_pressed_color", INK)
	button.add_theme_color_override("font_focus_color", INK)
	button.add_theme_stylebox_override("normal", _button_style(accent, 0.12))
	button.add_theme_stylebox_override("hover", _button_style(accent, 0.28))
	button.add_theme_stylebox_override("pressed", _button_style(accent, 0.42))
	button.add_theme_stylebox_override("focus", _button_style(accent, 0.22))
	button.focus_mode = Control.FOCUS_ALL
	return button

func _button_style(accent: Color, fill_alpha: float) -> StyleBoxFlat:
	var style: StyleBoxFlat = StyleBoxFlat.new()
	style.bg_color = Color(accent, fill_alpha)
	style.border_color = Color(accent, 0.9)
	style.set_border_width_all(1)
	style.corner_radius_top_left = 1
	style.corner_radius_top_right = 1
	style.corner_radius_bottom_left = 1
	style.corner_radius_bottom_right = 1
	style.content_margin_left = 18.0
	style.content_margin_right = 18.0
	return style

func _panel_style(accent: Color, alpha: float) -> StyleBoxFlat:
	var style: StyleBoxFlat = StyleBoxFlat.new()
	style.bg_color = Color(PANEL, alpha)
	style.border_color = Color(accent, 0.82)
	style.set_border_width_all(1)
	style.corner_radius_top_left = 1
	style.corner_radius_top_right = 1
	style.corner_radius_bottom_left = 1
	style.corner_radius_bottom_right = 1
	style.shadow_color = Color(0.0, 0.0, 0.0, 0.7)
	style.shadow_size = 14
	return style

func _on_start_pressed() -> void:
	visible = false
	EventBus.run_start_requested.emit()

func _on_settings_pressed() -> void:
	_settings_open = not _settings_open
	_settings_panel.visible = _settings_open

func _on_quit_pressed() -> void:
	get_tree().quit()

func _unhandled_input(event: InputEvent) -> void:
	if not visible:
		return
	if event.is_action_pressed("ui_accept"):
		_on_start_pressed()
		get_viewport().set_input_as_handled()

func _draw() -> void:
	var screen: Vector2 = size
	draw_rect(Rect2(Vector2.ZERO, screen), Color("050A0D"), true)
	for x in range(0, int(screen.x) + 1, 48):
		draw_line(Vector2(x, 0.0), Vector2(x, screen.y), Color(0.25, 0.72, 0.63, 0.055), 1.0)
	for y in range(0, int(screen.y) + 1, 48):
		draw_line(Vector2(0.0, y), Vector2(screen.x, y), Color(0.25, 0.72, 0.63, 0.055), 1.0)
	draw_circle(Vector2(screen.x * 0.82, screen.y * 0.22), 300.0, Color(0.75, 0.16, 0.11, 0.055))
	draw_circle(Vector2(screen.x * 0.2, screen.y * 0.72), 280.0, Color(0.05, 0.68, 0.58, 0.05))
	draw_line(Vector2(48.0, 198.0), Vector2(screen.x - 48.0, 198.0), Color(MINT, 0.3), 1.0)
	draw_line(Vector2(screen.x * 0.5, 236.0), Vector2(screen.x * 0.5, screen.y - 62.0), Color(AMBER, 0.15), 1.0)
