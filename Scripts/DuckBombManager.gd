extends Node2D

@onready var Marker = $Marker2D
@onready var Sprite = $AnimatedSprite2D
@onready var RayCast = $RayCast2D

var DuckNode = preload("res://Scenes/DuckBomb.tscn")

var TotalDucks = 3
var TimeyTimey = 0.0
var OscillationSpeed = 10.0  # higher = faster 
var Secondary = ""



# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	Sprite.modulate = Color(1,1,1,0.5)
	
	if get_parent().name == "Player1":
		Secondary = "SECONDARY"
	elif get_parent().name == "Player2":
		Secondary = "SECONDARY_2"
	elif get_parent().name == "Player3":
		Secondary = "SECONDARY_3"
	elif get_parent().name == "Player4":
		Secondary = "SECONDARY_4"

func _process(delta: float) -> void:
	TimeyTimey += delta
	var Opacity = (sin(TimeyTimey * OscillationSpeed) + 1.0) / 2.0
	Sprite.modulate = Color(1, 1, 1, Opacity)
	
	scale.x = get_parent().Direction * -1
	
	if Input.is_action_just_pressed(Secondary) and RayCast.is_colliding():
		TotalDucks -= 1
		var Duck = DuckNode.instantiate()
		Duck.global_position = Marker.global_position
		get_tree().current_scene.add_child(Duck)
	
	if TotalDucks == 0:
		queue_free()
			
