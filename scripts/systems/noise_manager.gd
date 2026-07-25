class_name NoiseManager
extends Node

## 噪声系统：临时噪声快速衰减，部分噪声转为残留噪声。
@export var temporary_decay_per_second: float = 8.0
@export var residual_decay_per_second: float = 0.2
@export var boss_threshold: float = 200.0

var temporary_noise: float = 0.0
var residual_noise: float = 0.0
var boss_threshold_reached: bool = false

func _ready() -> void:
    EventBus.noise_emitted.connect(_on_noise_emitted)

func _process(delta: float) -> void:
    temporary_noise = maxf(temporary_noise - temporary_decay_per_second * delta, 0.0)
    residual_noise = maxf(residual_noise - residual_decay_per_second * delta, 0.0)
    EventBus.noise_changed.emit(temporary_noise, residual_noise)

func _on_noise_emitted(amount: int, _position: Vector2, _source: Node2D) -> void:
    if amount <= 0:
        return
    temporary_noise += float(amount)
    residual_noise += float(amount) * 0.15
    if not boss_threshold_reached and temporary_noise + residual_noise >= boss_threshold:
        boss_threshold_reached = true
        EventBus.boss_awakened.emit(null)
