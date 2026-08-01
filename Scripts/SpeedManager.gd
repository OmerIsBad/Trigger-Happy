extends Node2D
@onready var TimeBar = $TimeBar
@onready var SpeedLife = $SpeedLife
var BoostedSpeed = 1.5
var BoostedAccel = 1.7
var GhostTimer = 0.0
var GhostInterval = 0.05

func _ready() -> void:
	var FillStyle = (TimeBar.get_theme_stylebox("fill") as StyleBoxTexture).duplicate()
	if get_parent().name == "Player1":
		FillStyle.modulate_color = Color("b51111")
	elif get_parent().name == "Player2":
		FillStyle.modulate_color = Color("115bb5")
	elif get_parent().name == "Player3":
		FillStyle.modulate_color = Color("33af22")
	elif get_parent().name == "Player4":
		FillStyle.modulate_color = Color("ffdb00")
	
	TimeBar.add_theme_stylebox_override("fill", FillStyle)

func _process(delta: float) -> void:
	TimeBar.value = (SpeedLife.time_left / SpeedLife.wait_time) * 100
	
	GhostTimer += delta
	if GhostTimer >= GhostInterval:
		GhostTimer = 0.0
		SpawnGhost()

func SpawnGhost() -> void:
	var PlayerSprite = get_parent().AnimatedSprite
	
	var Ghost = Sprite2D.new()
	Ghost.texture = PlayerSprite.sprite_frames.get_frame_texture(PlayerSprite.animation, PlayerSprite.frame)
	Ghost.global_position = PlayerSprite.global_position
	Ghost.global_rotation = PlayerSprite.global_rotation
	Ghost.scale = PlayerSprite.scale * get_parent().scale
	Ghost.flip_h = PlayerSprite.flip_h
	Ghost.modulate = Color(1.0, 1.0, 1.0, 0.5)
	Ghost.z_index = PlayerSprite.z_index - 1
	
	get_tree().current_scene.add_child(Ghost)
	
	var FadeTween = Ghost.create_tween()
	FadeTween.tween_property(Ghost, "modulate:a", 0.0, 0.3)
	FadeTween.tween_callback(Ghost.queue_free)

func _on_timer_timeout() -> void:
	queue_free()
