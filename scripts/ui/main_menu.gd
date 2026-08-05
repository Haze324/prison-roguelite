class_name MainMenuUI
extends Control

## 主菜单成品层：背景、文本、按钮和动态氛围完全拆分。
## 背景素材只负责环境；本脚本负责可交互 UI 和状态动画。

const INK: Color = Color("E2E1D5")
const MUTED: Color = Color("9A9A8C")
const STEEL: Color = Color("3B413D")
const PANEL: Color = Color("101516")
const TEAL: Color = Color("61D2BF")
const AMBER: Color = Color("D2A24D")
const RED: Color = Color("B84D45")
const BACKGROUND_PATH: String = "res://assets/generated/ui/main_menu_background_clean_v1.png"
const TITLE_FONT_PATH: String = "res://assets/fonts/prison_title_agency_b.ttf"
const TERMINAL_FONT_PATH: String = "res://assets/fonts/prison_terminal_mono.ttf"

@export_group("主菜单文案")
@export var title_text: String = "PRISON"
@export var subtitle_text: String = "SILENT ESCAPE"
@export var plaque_text: String = "ACCESS TERMINAL"
@export var primary_button_text: String = "▶   START RUN"
@export var settings_button_text: String = "SETTINGS"
@export var quit_button_text: String = "QUIT"

@export_group("主菜单版式")
@export var title_font_size: int = 100
@export var title_rotation_degrees: float = -0.8
@export var console_rotation_degrees: float = -3.0

var _background: TextureRect
var _ambient: MainMenuAmbient
var _modal_shade: ColorRect
var _transition_cover: ColorRect
var _start_button: Button
var _settings_button: Button
var _quit_button: Button
var _settings_panel: Panel
var _settings_close_button: Button
var _warning_label: Label
var _power_label: Label
var _settings_open: bool = false
var _transitioning: bool = false
var _layout_size: Vector2 = Vector2.ZERO
var _time: float = 0.0
var _last_focus: Control
var _button_base_positions: Dictionary = {}
var _title_font: Font
var _terminal_font: Font

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_STOP
	_title_font = load(TITLE_FONT_PATH) as Font
	_terminal_font = load(TERMINAL_FONT_PATH) as Font
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
	_time += delta
	if _background != null:
		var breath: float = 1.018 + sin(_time * 0.20) * 0.0025
		_background.scale = Vector2(breath, breath)
	if _warning_label != null:
		_warning_label.modulate.a = 0.62 + sin(_time * 1.4) * 0.20
	if _power_label != null:
		_power_label.modulate.a = 0.70 + sin(_time * 0.72 + 1.0) * 0.12

func _build_components() -> void:
	_background = TextureRect.new()
	_background.name = "MainMenuBackground"
	_background.texture = load(BACKGROUND_PATH) as Texture2D
	_background.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	_background.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
	_background.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_background.z_index = -10
	add_child(_background)

	_ambient = MainMenuAmbient.new()
	_ambient.name = "AmbientOverlay"
	_ambient.z_index = -5
	add_child(_ambient)

	_modal_shade = ColorRect.new()
	_modal_shade.name = "ModalShade"
	_modal_shade.color = Color(0.0, 0.0, 0.0, 0.0)
	_modal_shade.mouse_filter = Control.MOUSE_FILTER_STOP
	_modal_shade.visible = false
	add_child(_modal_shade)

	_transition_cover = ColorRect.new()
	_transition_cover.name = "TransitionCover"
	_transition_cover.color = Color(0.0, 0.0, 0.0, 0.0)
	_transition_cover.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_transition_cover.z_index = 30
	add_child(_transition_cover)

	var facility: Label = _label("FACILITY CONTROL  /  NIGHT SHIFT", 11, TEAL, _terminal_font)
	facility.name = "FacilityLabel"
	facility.visible = false
	add_child(facility)

	var title: Label = _label(title_text, title_font_size, INK, _title_font)
	title.name = "Title"
	title.rotation_degrees = title_rotation_degrees
	title.add_theme_color_override("font_shadow_color", Color(0.0, 0.0, 0.0, 0.95))
	title.add_theme_constant_override("shadow_offset_x", 3)
	title.add_theme_constant_override("shadow_offset_y", 3)
	title.add_theme_constant_override("outline_size", 1)
	title.add_theme_color_override("font_outline_color", Color(0.0, 0.0, 0.0, 0.78))
	var title_shader: Shader = Shader.new()
	title_shader.code = "shader_type canvas_item;\nvoid fragment() {\n    vec4 base = texture(TEXTURE, UV);\n    float grain = fract(sin(dot(UV * vec2(360.0, 260.0), vec2(12.9898, 78.233))) * 43758.5453);\n    if (grain > 0.94) { base.rgb *= 0.58; }\n    COLOR = base;\n}"
	var title_material: ShaderMaterial = ShaderMaterial.new()
	title_material.shader = title_shader
	title.material = title_material
	add_child(title)

	var subtitle: Label = _label(subtitle_text, 16, TEAL, _terminal_font)
	subtitle.name = "Subtitle"
	subtitle.rotation_degrees = -0.8
	subtitle.add_theme_constant_override("outline_size", 2)
	subtitle.add_theme_color_override("font_outline_color", Color(0.0, 0.0, 0.0, 0.9))
	add_child(subtitle)

	var descriptor: Label = _label("SOLO EXTRACTION  /  LOW-LIGHT FACILITY", 12, MUTED, _terminal_font)
	descriptor.name = "Descriptor"
	descriptor.visible = false
	add_child(descriptor)

	var action_panel: Panel = Panel.new()
	action_panel.name = "ActionPanel"
	action_panel.add_theme_stylebox_override("panel", _panel_style(Color(STEEL, 0.42), 0.05, 0))
	action_panel.mouse_filter = Control.MOUSE_FILTER_PASS
	add_child(action_panel)

	var terminal_label: Label = _label(plaque_text + "  /  STANDBY", 11, MUTED, _terminal_font)
	terminal_label.name = "TerminalLabel"
	terminal_label.position = Vector2(22.0, 10.0)
	terminal_label.size = Vector2(300.0, 20.0)
	action_panel.add_child(terminal_label)

	_start_button = _make_button(primary_button_text, TEAL, true)
	_start_button.name = "StartButton"
	_start_button.pressed.connect(_on_start_pressed)
	action_panel.add_child(_start_button)

	_settings_button = _make_button(settings_button_text, AMBER, false)
	_settings_button.name = "SettingsButton"
	_settings_button.pressed.connect(_on_settings_pressed)
	action_panel.add_child(_settings_button)

	_quit_button = _make_button(quit_button_text, MUTED, false)
	_quit_button.name = "QuitButton"
	_quit_button.pressed.connect(_on_quit_pressed)
	action_panel.add_child(_quit_button)

	_warning_label = _label("ALARM SYSTEM  /  MONITORING", 11, RED, _terminal_font)
	_warning_label.name = "WarningStatus"
	_warning_label.visible = false
	add_child(_warning_label)
	_power_label = _label("POWER CORE  /  STABLE", 11, TEAL, _terminal_font)
	_power_label.name = "PowerStatus"
	_power_label.visible = false
	add_child(_power_label)

	var hint: Label = _label("ENTER / CONFIRM   ↑↓ / SELECT   ESC / RETURN", 10, MUTED, _terminal_font)
	hint.name = "InputHint"
	hint.visible = false
	add_child(hint)

	var version: Label = _label("SURVIVOR PROTOCOL  /  DEMO", 10, Color(MUTED, 0.76), _terminal_font)
	version.name = "VersionLabel"
	version.visible = false
	version.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	add_child(version)

	_settings_panel = _build_settings_panel()
	add_child(_settings_panel)
	_setup_focus_order()

func _build_settings_panel() -> Panel:
	var panel: Panel = Panel.new()
	panel.name = "SettingsDrawer"
	panel.visible = false
	panel.modulate.a = 0.0
	panel.mouse_filter = Control.MOUSE_FILTER_STOP
	panel.add_theme_stylebox_override("panel", _panel_style(AMBER, 0.96, 2))

	var title: Label = _label("TERMINAL SETTINGS", 20, INK, _terminal_font)
	title.position = Vector2(24.0, 22.0)
	title.size = Vector2(270.0, 30.0)
	panel.add_child(title)
	var caption: Label = _label("CURRENT RUN CONFIGURATION", 10, MUTED, _terminal_font)
	caption.position = Vector2(24.0, 56.0)
	caption.size = Vector2(270.0, 20.0)
	panel.add_child(caption)

	var resolution: Label = _label("DISPLAY\n1280 x 720", 12, INK, _terminal_font)
	resolution.position = Vector2(24.0, 96.0)
	resolution.size = Vector2(160.0, 48.0)
	panel.add_child(resolution)
	var resolution_state: Label = _label("LOCKED", 10, TEAL, _terminal_font)
	resolution_state.position = Vector2(200.0, 104.0)
	resolution_state.size = Vector2(72.0, 24.0)
	resolution_state.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	panel.add_child(resolution_state)

	var audio: Label = _label("AUDIO\nDEFAULT MIX", 12, INK, _terminal_font)
	audio.position = Vector2(24.0, 158.0)
	audio.size = Vector2(160.0, 48.0)
	panel.add_child(audio)
	var audio_state: Label = _label("ON", 10, TEAL, _terminal_font)
	audio_state.position = Vector2(200.0, 166.0)
	audio_state.size = Vector2(72.0, 24.0)
	audio_state.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	panel.add_child(audio_state)

	_settings_close_button = _make_button("RETURN TO TERMINAL", AMBER, false)
	_settings_close_button.position = Vector2(24.0, 228.0)
	_settings_close_button.size = Vector2(252.0, 42.0)
	_settings_close_button.pressed.connect(_on_settings_pressed)
	panel.add_child(_settings_close_button)
	return panel

func _layout_components() -> void:
	_layout_size = size
	if size.x <= 0.0 or size.y <= 0.0:
		return
	var narrow: bool = size.x < 900.0
	var left: float = 54.0 if narrow else size.x * 0.105
	var action_width: float = minf(490.0, size.x * 0.36)
	# 当前项目在 Windows 高 DPI 下可能以逻辑视口绘制到较小客户区，
	# 因此操作区使用上限，避免底部按钮被窗口边缘裁切。
	var action_y: float = minf(size.y * 0.40, 285.0)

	_background.position = Vector2(-size.x * 0.022, -size.y * 0.022)
	_background.size = size * 1.044
	_background.pivot_offset = _background.size * 0.5
	_ambient.position = Vector2.ZERO
	_ambient.size = size
	_modal_shade.position = Vector2.ZERO
	_modal_shade.size = size
	_transition_cover.position = Vector2.ZERO
	_transition_cover.size = size

	_set_rect("FacilityLabel", Vector2(left + 8.0, size.y * 0.055), Vector2(440.0, 20.0))
	_set_rect("Title", Vector2(left, size.y * 0.055), Vector2(560.0, 120.0))
	_set_rect("Subtitle", Vector2(left + 4.0, size.y * 0.205), Vector2(360.0, 26.0))
	_set_rect("Descriptor", Vector2(left + 4.0, size.y * 0.25), Vector2(360.0, 22.0))

	var action_panel: Panel = get_node("ActionPanel") as Panel
	action_panel.position = Vector2(left, action_y)
	action_panel.size = Vector2(action_width, 194.0)
	action_panel.pivot_offset = action_panel.size * 0.5
	action_panel.rotation_degrees = console_rotation_degrees
	_start_button.position = Vector2(22.0, 34.0)
	_start_button.size = Vector2(action_width - 44.0, 62.0)
	_settings_button.position = Vector2(22.0, 112.0)
	_settings_button.size = Vector2((action_width - 54.0) * 0.5, 42.0)
	_quit_button.position = Vector2(32.0 + (action_width - 54.0) * 0.5, 112.0)
	_quit_button.size = Vector2((action_width - 54.0) * 0.5, 42.0)
	_button_base_positions[_start_button] = _start_button.position
	_button_base_positions[_settings_button] = _settings_button.position
	_button_base_positions[_quit_button] = _quit_button.position

	_set_rect("WarningStatus", Vector2(left + action_width + 34.0, action_y + 102.0), Vector2(210.0, 20.0))
	_set_rect("PowerStatus", Vector2(left + action_width + 34.0, action_y + 126.0), Vector2(210.0, 20.0))
	_warning_label.rotation_degrees = -3.0
	_power_label.rotation_degrees = -3.0
	var footer_y: float = minf(size.y - 54.0, 486.0)
	_set_rect("InputHint", Vector2(left, footer_y), Vector2(330.0, 20.0))
	_set_rect("VersionLabel", Vector2(size.x - left - 300.0, footer_y), Vector2(300.0, 20.0))

	var drawer_width: float = 320.0 if size.x >= 700.0 else size.x - 48.0
	_settings_panel.position = Vector2(size.x - drawer_width - left, size.y * 0.12)
	_settings_panel.size = Vector2(drawer_width, 294.0)

func _set_rect(node_name: String, position: Vector2, node_size: Vector2) -> void:
	var node: Control = get_node_or_null(NodePath(node_name)) as Control
	if node == null:
		return
	node.position = position
	node.size = node_size

func _label(text_value: String, font_size: int, color: Color, font: Font = null) -> Label:
	var label: Label = Label.new()
	label.text = text_value
	label.add_theme_font_size_override("font_size", font_size)
	label.add_theme_color_override("font_color", color)
	if font != null:
		label.add_theme_font_override("font", font)
	label.add_theme_color_override("font_shadow_color", Color(0.0, 0.0, 0.0, 0.88))
	label.add_theme_constant_override("shadow_offset_x", 1)
	label.add_theme_constant_override("shadow_offset_y", 1)
	label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return label

func _make_button(text_value: String, accent: Color, primary: bool) -> Button:
	var button: Button = Button.new()
	button.text = text_value
	if _terminal_font != null:
		button.add_theme_font_override("font", _terminal_font)
	button.add_theme_font_size_override("font_size", 18 if primary else 14)
	button.add_theme_color_override("font_color", INK)
	button.add_theme_color_override("font_hover_color", Color.WHITE)
	button.add_theme_color_override("font_pressed_color", Color.WHITE)
	button.add_theme_color_override("font_focus_color", INK)
	button.add_theme_stylebox_override("normal", _button_style(accent, 0.12, primary))
	button.add_theme_stylebox_override("hover", _button_style(accent, 0.30, primary))
	button.add_theme_stylebox_override("pressed", _button_style(accent, 0.46, primary))
	button.add_theme_stylebox_override("focus", _button_style(accent, 0.22, primary))
	button.add_theme_stylebox_override("disabled", _button_style(STEEL, 0.05, false))
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
	style.border_color = Color(accent, 0.94 if primary else 0.64)
	style.set_border_width_all(1)
	style.border_width_left = 3 if primary else 1
	style.corner_radius_top_left = 2
	style.corner_radius_top_right = 2
	style.corner_radius_bottom_left = 2
	style.corner_radius_bottom_right = 2
	style.content_margin_left = 20.0
	style.content_margin_right = 20.0
	return style

func _panel_style(accent: Color, alpha: float, border_width: int) -> StyleBoxFlat:
	var style: StyleBoxFlat = StyleBoxFlat.new()
	style.bg_color = Color(PANEL, alpha)
	style.border_color = Color(accent, 0.66)
	style.set_border_width_all(border_width)
	style.corner_radius_top_left = 2
	style.corner_radius_top_right = 2
	style.corner_radius_bottom_left = 2
	style.corner_radius_bottom_right = 2
	style.shadow_color = Color(0.0, 0.0, 0.0, 0.78)
	style.shadow_size = 18
	return style

func _setup_focus_order() -> void:
	_start_button.focus_next = _settings_button.get_path()
	_settings_button.focus_previous = _start_button.get_path()
	_settings_button.focus_next = _quit_button.get_path()
	_quit_button.focus_previous = _settings_button.get_path()
	_start_button.focus_neighbor_bottom = _settings_button.get_path()
	_settings_button.focus_neighbor_top = _start_button.get_path()
	_settings_button.focus_neighbor_right = _quit_button.get_path()
	_settings_button.focus_neighbor_bottom = _quit_button.get_path()
	_quit_button.focus_neighbor_left = _settings_button.get_path()
	_quit_button.focus_neighbor_top = _start_button.get_path()

func _on_button_hover(button: Button, hovered: bool) -> void:
	if button == null or button.disabled:
		return
	_animate_button(button, hovered)

func _on_button_focus(button: Button, focused: bool) -> void:
	if button == null or button.disabled:
		return
	_animate_button(button, focused)

func _on_button_pressed(button: Button) -> void:
	if button == null:
		return
	var base: Vector2 = _button_base_positions.get(button, button.position)
	var tween: Tween = create_tween()
	tween.tween_property(button, "position", base + Vector2(2.0, 2.0), 0.06)
	tween.tween_property(button, "position", base, 0.16)

func _animate_button(button: Button, active: bool) -> void:
	var base: Vector2 = _button_base_positions.get(button, button.position)
	var target: Vector2 = base + Vector2(6.0, 0.0) if active else base
	var tween: Tween = create_tween()
	tween.set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	tween.tween_property(button, "position", target, 0.13)

func _play_intro() -> void:
	for node_name in ["FacilityLabel", "Title", "Subtitle", "Descriptor", "ActionPanel", "WarningStatus", "PowerStatus", "InputHint", "VersionLabel"]:
		var node: Control = get_node_or_null(NodePath(node_name)) as Control
		if node == null:
			continue
		node.modulate.a = 0.0
		var delay: float = 0.04 * float(["FacilityLabel", "Title", "Subtitle", "Descriptor", "ActionPanel", "WarningStatus", "PowerStatus", "InputHint", "VersionLabel"].find(node_name))
		var tween: Tween = create_tween()
		tween.tween_interval(delay)
		tween.tween_property(node, "modulate:a", 1.0, 0.30)

func _on_start_pressed() -> void:
	if _transitioning:
		return
	_transitioning = true
	_set_main_buttons_enabled(false)
	_transition_cover.visible = true
	var tween: Tween = create_tween()
	tween.set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
	tween.tween_property(_transition_cover, "color:a", 1.0, 0.24)
	tween.tween_callback(_emit_run_start)

func _emit_run_start() -> void:
	visible = false
	EventBus.run_start_requested.emit()

func _on_settings_pressed() -> void:
	if _transitioning:
		return
	_settings_open = not _settings_open
	if _settings_open:
		_last_focus = get_viewport().gui_get_focus_owner()
		_set_main_buttons_enabled(false)
		_modal_shade.visible = true
		_settings_panel.visible = true
		_settings_panel.position.x += 28.0
		var show_tween: Tween = create_tween()
		show_tween.set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
		show_tween.parallel().tween_property(_modal_shade, "color:a", 0.44, 0.20)
		show_tween.parallel().tween_property(_settings_panel, "position:x", _settings_panel.position.x - 28.0, 0.24)
		show_tween.parallel().tween_property(_settings_panel, "modulate:a", 1.0, 0.24)
		show_tween.tween_callback(_settings_close_button.grab_focus)
	else:
		var hide_tween: Tween = create_tween()
		hide_tween.set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
		hide_tween.parallel().tween_property(_modal_shade, "color:a", 0.0, 0.16)
		hide_tween.parallel().tween_property(_settings_panel, "position:x", _settings_panel.position.x + 28.0, 0.18)
		hide_tween.parallel().tween_property(_settings_panel, "modulate:a", 0.0, 0.18)
		hide_tween.tween_callback(_settings_panel.hide)
		hide_tween.tween_callback(_modal_shade.hide)
		hide_tween.tween_callback(_restore_menu_focus)
		_set_main_buttons_enabled(true)

func _restore_menu_focus() -> void:
	if _last_focus != null and is_instance_valid(_last_focus) and _last_focus != _settings_close_button:
		_last_focus.grab_focus()
	else:
		_start_button.grab_focus()

func _set_main_buttons_enabled(enabled: bool) -> void:
	_start_button.disabled = not enabled
	_settings_button.disabled = not enabled
	_quit_button.disabled = not enabled

func _on_quit_pressed() -> void:
	get_tree().quit()

func _unhandled_input(event: InputEvent) -> void:
	if not visible:
		return
	if event.is_action_pressed("ui_cancel") and _settings_open:
		_on_settings_pressed()
		get_viewport().set_input_as_handled()

func _draw() -> void:
	# 背景图负责所有主要美术；此处只保留极轻的终端边缘标记。
	if size.x <= 0.0 or size.y <= 0.0:
		return
	draw_line(Vector2(26.0, 26.0), Vector2(size.x - 26.0, 26.0), Color(AMBER, 0.20), 1.0)
	draw_line(Vector2(26.0, 26.0), Vector2(26.0, size.y - 28.0), Color(AMBER, 0.12), 1.0)
