extends Node

## 跨局保留数据：死亡不清空，重新开始只重置 Run 内资源。
var coins: int = 0
var skill_points: int = 0
var unlocked_skills: Dictionary = {}
var last_run_result: String = ""

func add_coins(amount: int) -> void:
    coins = maxi(coins + amount, 0)
    EventBus.meta_progression_changed.emit(coins, skill_points)

func add_skill_points(amount: int) -> void:
    skill_points = maxi(skill_points + amount, 0)
    EventBus.meta_progression_changed.emit(coins, skill_points)

func unlock_skill(skill_name: String, cost: int = 1) -> bool:
    if unlocked_skills.has(skill_name) or skill_points < cost:
        return false
    skill_points -= cost
    unlocked_skills[skill_name] = true
    EventBus.skill_unlocked.emit(skill_name)
    EventBus.meta_progression_changed.emit(coins, skill_points)
    return true

func record_run(result: String) -> void:
    last_run_result = result
