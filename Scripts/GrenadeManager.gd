extends Node2D
var GrenadeScene = preload("res://Scenes/Grenade.tscn")
var Secondary = ""
var PercentForce = 0.25 
var MaxChargeTime = 1.0
var HoldStartTime = 0
var GrenadesLeft = 5
@onready var PowerBar = $PowerBar

func _ready() -> void:
	var FillStyle = (PowerBar.get_theme_stylebox("fill") as StyleBoxTexture).duplicate()
	
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
		
	PowerBar.add_theme_stylebox_override("fill", FillStyle)
	PowerBar.visible = false

func _process(delta: float) -> void:
	if Input.is_action_just_pressed(Secondary):
		HoldStartTime = Time.get_ticks_msec()
		PowerBar.visible = true
	
	if Input.is_action_pressed(Secondary):
		var HeldDuration = (Time.get_ticks_msec() - HoldStartTime) / 1000.0
		var CurrentChargePercent = clamp(HeldDuration / MaxChargeTime, 0.0, 1.0)
		PowerBar.value = CurrentChargePercent * 100
	
	if Input.is_action_just_released(Secondary):
		var HeldDuration = (Time.get_ticks_msec() - HoldStartTime) / 1000.0
		PercentForce = clamp(HeldDuration / MaxChargeTime, 0.25, 1.0)
		
		GrenadesLeft -= 1
		
		var Grenade = GrenadeScene.instantiate()
		Grenade.global_position = global_position
		Grenade.Direction = get_parent().Direction
		Grenade.PercentForce = PercentForce
		get_tree().current_scene.add_child(Grenade)
		
		PowerBar.visible = false
	
	if GrenadesLeft == 0:
		queue_free()
