class_name SpriteFramesFactory
extends RefCounted

## 从横向 spritesheet 创建 SpriteFrames。每张图只允许一行动画帧。
static func build_from_sheet(path: String, frame_count: int, fps: float, loop: bool) -> SpriteFrames:
	var image: Image = Image.load_from_file(path)
	if image == null or image.is_empty():
		push_error("无法加载 spritesheet: " + path)
		return null
	var frame_width: int = image.get_width() / frame_count
	var frames: SpriteFrames = SpriteFrames.new()
	frames.remove_animation("default")
	frames.add_animation("default")
	frames.set_animation_loop("default", loop)
	for index in frame_count:
		var region: Image = image.get_region(Rect2i(index * frame_width, 0, frame_width, image.get_height()))
		frames.add_frame("default", ImageTexture.create_from_image(region), 1.0 / fps)
	return frames

static func build_player_frames(base_path: String) -> SpriteFrames:
	var frames: SpriteFrames = SpriteFrames.new()
	frames.remove_animation("default")
	# 角色素材为 384x64，每张横向排列 8 帧，每帧 48x64。
	_add_animation(frames, "idle", base_path + "idle.png", 8, 10.0, true)
	_add_animation(frames, "walk", base_path + "walk.png", 8, 12.0, true)
	_add_animation(frames, "dash", base_path + "dash.png", 8, 15.0, false)
	_add_animation(frames, "death", base_path + "death.png", 8, 8.0, false)
	ensure_player_action_animations(frames, base_path)
	return frames

## 为现有角色资源补齐动作轨道。专用动作美术替换前，使用已批准的角色帧保持动作节奏和状态机接口稳定。
static func ensure_player_action_animations(frames: SpriteFrames, base_path: String) -> void:
	if frames == null:
		return
	_add_animation_if_missing(frames, "reload", base_path + "idle.png", 8, 14.0, false)
	_add_animation_if_missing(frames, "heal", base_path + "idle.png", 8, 10.0, false)
	_add_animation_if_missing(frames, "resupply", base_path + "idle.png", 8, 9.0, false)
	_add_animation_if_missing(frames, "throw", base_path + "walk.png", 8, 16.0, false)
	_add_animation_if_missing(frames, "parry", base_path + "dash.png", 8, 18.0, false)
	_add_animation_if_missing(frames, "perfect_parry", base_path + "dash.png", 8, 22.0, false)
	_add_animation_if_missing(frames, "hurt", base_path + "idle.png", 8, 20.0, false)
	_add_animation_if_missing(frames, "melee_swing", base_path + "dash.png", 8, 24.0, false)

static func _add_animation_if_missing(frames: SpriteFrames, animation_name: String, path: String, frame_count: int, fps: float, loop: bool) -> void:
	if not frames.has_animation(animation_name):
		_add_animation(frames, animation_name, path, frame_count, fps, loop)

static func build_monster_frames(base_path: String, animation_prefix: String) -> SpriteFrames:
	var frames: SpriteFrames = SpriteFrames.new()
	frames.remove_animation("default")
	_add_animation(frames, "idle", base_path + animation_prefix + "_idle.png", 6, 5.0, true)
	_add_animation(frames, "walk", base_path + animation_prefix + "_walk.png", 8, 8.0, true)
	_add_animation(frames, "attack", base_path + animation_prefix + "_attack01.png", 7, 10.0, false)
	_add_animation(frames, "hurt", base_path + animation_prefix + "_hurt.png", 4, 8.0, false)
	_add_animation(frames, "death", base_path + animation_prefix + "_death.png", 4, 6.0, false)
	return frames

static func _add_animation(frames: SpriteFrames, animation_name: String, path: String, frame_count: int, fps: float, loop: bool) -> void:
	var image: Image = Image.load_from_file(path)
	if image == null or image.is_empty():
		push_error("无法加载动画素材: " + path)
		return
	if image.get_width() % frame_count != 0:
		push_error("动画素材宽度无法按帧数整除: %s, frame_count=%d" % [path, frame_count])
		return
	var frame_width: int = image.get_width() / frame_count
	frames.add_animation(animation_name)
	frames.set_animation_loop(animation_name, loop)
	for index in frame_count:
		var region: Image = image.get_region(Rect2i(index * frame_width, 0, frame_width, image.get_height()))
		frames.add_frame(animation_name, ImageTexture.create_from_image(region), 1.0 / fps)
