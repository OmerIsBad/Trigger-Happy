extends Node2D

var Power = 100.0
var MaxSpeed = 750.0

@onready var FuelTimer = $FuelTimer
@onready var AnimatedSprite = $SpriteHolder/AnimatedSprite2D
@onready var FuelBar = $FuelBar
@onready var SpriteHolder = $SpriteHolder
@onready var BurnSFX = $BurnBabyBurn
@onready var FireSFX = $FireSFX
var Secondary = ""


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	var FillStyle = (FuelBar.get_theme_stylebox("fill") as StyleBoxTexture).duplicate()

	FuelTimer.start()
	FuelTimer.paused = true
	
	if get_parent().name == "Player1":
		Secondary = "SECONDARY"
		FillStyle.modulate_color = Color("b51111")
	elif get_parent().name == "Player2":
		Secondary = "SECONDARY_2"
		FillStyle.modulate_color = Color("115bb5")
	elif get_parent().name == "Player3":
		Secondary = "SECONDARY_3"
		FillStyle.modulate_color = Color("33af22")
	elif get_parent().name == "Player4":
		Secondary = "SECONDARY_4"
		FillStyle.modulate_color = Color("ffdb00")
	
	FuelBar.add_theme_stylebox_override("fill", FillStyle)


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float):
	FuelBar.value = (FuelTimer.time_left / FuelTimer.wait_time) * 100
	if Input.is_action_pressed(Secondary):
		if !BurnSFX.playing:
			BurnSFX.play()
			FireSFX.play(0.2)
		FuelTimer.paused = false
		AnimatedSprite.play("On")
		if get_parent().velocity.y > -MaxSpeed:
			get_parent().velocity.y -= Power
	else:
		if BurnSFX.playing:
			BurnSFX.stop()
		FuelTimer.paused = true
		AnimatedSprite.play("Off")
	
	SpriteHolder.scale.x = -get_parent().Direction


func _on_fuel_timer_timeout() -> void:
	queue_free()
