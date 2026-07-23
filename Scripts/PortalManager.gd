extends Node2D

@onready var Sprite = $AnimatedSprite2D
@onready var Marker = $Marker2D

var PortalBlueNode = preload("res://Scenes/PortalBlue.tscn")
var PortalOrangeNode = preload("res://Scenes/PortalOrange.tscn")


var TimeyTimey = 0.0
var OscillationSpeed = 10.0  # higher = faster 
var Secondary = ""

var PortalsLeft = 2



# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	Sprite.play("Blue")
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
	
	#Placement Logic
	if Input.is_action_just_pressed(Secondary):
		if PortalsLeft == 2:
			var BluePortal = PortalBlueNode.instantiate()
			BluePortal.global_position = Marker.global_position
			get_tree().current_scene.add_child(BluePortal)
			PortalsLeft -= 1
			Sprite.play("Orange")
		elif PortalsLeft == 1:
			var OrangePortal = PortalOrangeNode.instantiate()
			OrangePortal.global_position = Marker.global_position
			get_tree().current_scene.add_child(OrangePortal)
			for Portal in get_tree().get_nodes_in_group("Portals"):
				if Portal.Activated != true:
					Portal.Activated = true
					Portal.Lifetime.start()
			
			get_parent().IsAPunch = false 
			queue_free()
