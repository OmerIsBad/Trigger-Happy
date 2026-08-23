extends Node2D

@onready var MoveText = $MoveText
@export var Student = ""

var Dummy = preload("uid://2kx5irnd87eb")

func _ready() -> void:
	if Student == "Player2":
		MoveText.text = "Arrow Keys To Move Here"
		MoveText.add_theme_color_override("default_color", Color("115bb5"))
	elif Student == "Player3":
		MoveText.text = "YGHJ To Move Here"
		MoveText.add_theme_color_override("default_color", Color("33af22"))
	elif Student == "Player4":
		MoveText.text = "8456 To Move Here"
		MoveText.add_theme_color_override("default_color", Color("ffdb00"))

func _on_area_2d_body_entered(body: Node2D) -> void:
	if body.name == Student:
		var NewDummy = Dummy.instantiate()
		
		var PositionNodeNames = {
			"Player1": "PositionNode",
			"Player2": "PositionNode2",
			"Player3": "PositionNode3",
			"Player4": "PositionNode4",
		}
		
		if PositionNodeNames.has(Student):
			NewDummy.global_position = get_parent().get_node(PositionNodeNames[Student]).global_position
			NewDummy.Student = Student
		
		get_tree().current_scene.add_child(NewDummy)
	
		queue_free()
