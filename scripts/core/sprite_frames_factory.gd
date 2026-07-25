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
	return frames

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
