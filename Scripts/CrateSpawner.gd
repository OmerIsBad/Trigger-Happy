extends Node2D

@onready var SpawnInTimer = $SpawnInTimer
@onready var SpawnMarker = $SpawnMarker


var WeaponsCrate = preload("res://Scenes/WeaponCrate.tscn")
var MaxCrates = 2

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	RestartCrateShenanigans()

func RestartCrateShenanigans():
	var TimerTime = randi_range(10, 60)
	global_position.x += randi_range(-150, +150)
	SpawnInTimer.start(TimerTime)
	
func _on_spawn_in_timer_timeout() -> void:
	var NumberOfCrates = get_tree().get_nodes_in_group("WeaponCrates").size()
	if NumberOfCrates < MaxCrates:
		var WeaponBox = WeaponsCrate.instantiate()
		add_child(WeaponBox)
		WeaponBox.position = SpawnMarker.position
	else:
		RestartCrateShenanigans()
