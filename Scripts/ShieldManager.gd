extends Node2D

@onready var ShieldDuration = $ShieldDuration
@onready var ShieldBar = $ShieldBar

var ShieldNode = preload("res://Scenes/Shield.tscn")
var Shield = null
var Secondary = ""

var OldTopSpeed 


var SlowedSpeed = 250
var SlowedAcc = 5

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	var FillStyle = (ShieldBar.get_theme_stylebox("fill") as StyleBoxTexture).duplicate()
	
	OldTopSpeed = get_parent().TopSpeed
	
	ShieldDuration.start()
	ShieldDuration.paused = true
	
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
	
	ShieldBar.add_theme_stylebox_override("fill", FillStyle)
	


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	ShieldBar.value = (ShieldDuration.time_left / ShieldDuration.wait_time) * 100
	
	
	if Input.is_action_pressed(Secondary):
		ShieldDuration.paused = false
	else:
		ShieldDuration.paused = true
	
	if ShieldDuration.paused == false and Shield == null:
		Shield = ShieldNode.instantiate()
		
		Shield.ShieldDirection = get_parent().Direction
		
		add_child(Shield)
		
		if abs(get_parent().velocity.x) > SlowedSpeed:
			get_parent().velocity.x = SlowedSpeed * get_parent().Direction
		get_parent().TopSpeed = SlowedSpeed
		#get_parent().Acceleration = SlowedAcc
		
		
	if ShieldDuration.paused == true and Shield != null:
		Shield.queue_free()
		Shield = null
		
		get_parent().TopSpeed = OldTopSpeed
		#get_parent().Acceleration = OldAcc


func _on_shield_duration_timeout() -> void:
	if Shield != null:
		Shield.queue_free()
		Shield = null
	get_parent().TopSpeed = OldTopSpeed
	#get_parent().Acceleration = OldAcc
	
	get_parent().DropItem("Shield")
	
	queue_free()

func _exit_tree() -> void:
	get_parent().TopSpeed = OldTopSpeed
