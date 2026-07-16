extends Node2D
@onready var TextLabel = $Text
var KillMe = false
var Opacity = 1
var FadeOutSpeed = 0.1

var UpwardsBoostSpeed = 5 + randf_range(2, -2)
var UpwardsDecay = 0.9  # multiply by this each frame; closer to 1 = slower decay

var RotationSpeed = 0.05
var RotationDecay = 0.7 + randf_range(0.1, -0.1)

var RandomDirection = -1
var OutlineSize = 8

func _ready() -> void:
	RandomDirection = 1 if randi_range(0, 1) == 1 else -1
	TextLabel.add_theme_constant_override("outline_size", OutlineSize)

func _process(delta: float) -> void:
	if KillMe == true:
		Opacity -= FadeOutSpeed
		TextLabel.modulate = Color(1, 1, 1, Opacity)
		if Opacity <= 0:
			queue_free()
	
	#Upwards boost - exponential decay
	position.y -= UpwardsBoostSpeed
	UpwardsBoostSpeed *= UpwardsDecay
	
	#Rotation - exponential decay
	rotation -= RotationSpeed * RandomDirection
	RotationSpeed *= RotationDecay

func _on_lifetime_timeout() -> void:
	KillMe = true
