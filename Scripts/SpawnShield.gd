extends Node2D
@onready var Sprite = $Sprite2D

var TimeyTimey = 0.0
var OscillationSpeed = 7.5
var MinOpacity = 0.2
var MaxOpacity = 0.6

func _process(delta: float) -> void:
	TimeyTimey += delta
	var Wave = (sin(TimeyTimey * OscillationSpeed) + 1.0) / 2.0  # 0 to 1
	var Opacity = lerp(MinOpacity, MaxOpacity, Wave)
	Sprite.modulate = Color(1, 1, 1, Opacity)

func _on_lifetime_timeout() -> void:
	queue_free()
