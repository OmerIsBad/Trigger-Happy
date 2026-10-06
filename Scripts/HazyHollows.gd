extends Node2D
@onready var Spawn1 = $Spawn1
@onready var Spawn2 = $Spawn2
@onready var Spawn3 = $Spawn3
@onready var Spawn4 = $Spawn4

const PLAYER_1 = preload("uid://byftoioygd6js")
const PLAYER_2 = preload("uid://deth1no6loh1e")
const PLAYER_3 = preload("uid://dboxttpabx55w")
const PLAYER_4 = preload("uid://d0moe1qvk0f81")

var Player1Selected = false
var Player2Selected = false
var Player3Selected = false
var Player4Selected = false

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	if Player1Selected:
			var Player1 = PLAYER_1.instantiate()
			Player1.global_position = Spawn1.global_position
			add_child(Player1)
	
	if Player2Selected:
		var Player2 = PLAYER_2.instantiate()
		Player2.global_position = Spawn2.global_position
		add_child(Player2)
	
	if Player3Selected:
		var Player3 = PLAYER_3.instantiate()
		Player3.global_position = Spawn3.global_position
		add_child(Player3)
	
	if Player4Selected:
		var Player4 = PLAYER_4.instantiate()
		Player4.global_position = Spawn4.global_position
		add_child(Player4)
