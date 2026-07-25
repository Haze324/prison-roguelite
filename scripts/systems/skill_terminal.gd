class_name SkillTerminal
extends Node2D

const SKILLS: Array[String] = ["Quick Hands", "Silent Step", "Iron Will", "Field Medic"]

var player: Player

func setup(target: Player) -> void:
	player = target
	queue_redraw()

func _process(_delta: float) -> void:
	queue_redraw()
	if player == null or global_position.distance_to(player.global_position) > 48.0:
		return
	if Input.is_action_just_pressed("interact"):
		for skill_name in SKILLS:
			if not MetaProgression.unlocked_skills.has(skill_name):
				if MetaProgression.unlock_skill(skill_name):
					EventBus.consumable_used.emit("Skill unlocked: " + skill_name)
				else:
					EventBus.consumable_used.emit("Skill terminal: need 1 skill point")
				return
		EventBus.consumable_used.emit("All four skills unlocked")

func _draw() -> void:
	draw_rect(Rect2(-24.0, -30.0, 48.0, 60.0), Color(0.16, 0.09, 0.2, 1.0), true)
	draw_rect(Rect2(-24.0, -30.0, 48.0, 60.0), Color(0.82, 0.48, 0.95, 1.0), false, 2.0)
	draw_circle(Vector2.ZERO, 8.0, Color(0.82, 0.48, 0.95, 1.0))
	if player != null and global_position.distance_to(player.global_position) <= 100.0:
		draw_string(ThemeDB.fallback_font, Vector2(-38.0, -42.0), "SKILLS", HORIZONTAL_ALIGNMENT_LEFT, -1.0, 10, Color(0.9, 0.7, 1.0, 1.0))
		draw_string(ThemeDB.fallback_font, Vector2(-34.0, 48.0), "E: UNLOCK", HORIZONTAL_ALIGNMENT_LEFT, -1.0, 10, Color(0.9, 0.82, 0.55, 1.0))
