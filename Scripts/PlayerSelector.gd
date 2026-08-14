extends Control
@onready var Player1Box: CheckBox = $CheckBox
@onready var Player2Box: CheckBox = $CheckBox2
@onready var Player3Box: CheckBox = $CheckBox3
@onready var Player4Box: CheckBox = $CheckBox4
var Level = preload("res://Scenes/Level.tscn")

func _ready() -> void:
	pass

func _on_begin_button_pressed() -> void:
	var NewLevel = Level.instantiate()
	NewLevel.Player1Selected = Player1Box.button_pressed
	NewLevel.Player2Selected = Player2Box.button_pressed
	NewLevel.Player3Selected = Player3Box.button_pressed
	NewLevel.Player4Selected = Player4Box.button_pressed
	
	get_tree().root.add_child(NewLevel)
	get_tree().current_scene = NewLevel
	queue_free()
