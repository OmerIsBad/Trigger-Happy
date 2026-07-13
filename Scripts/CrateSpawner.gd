extends Node2D

@onready var SpawnInTimer = $SpawnInTimer
@onready var SpawnMarker = $SpawnMarker


var WeaponsCrate = preload("res://Scenes/WeaponCrate.tscn")

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	RestartCrateShenanigans()

func RestartCrateShenanigans():
	var TimerTime = randi_range(10, 100)
	global_position.x += randi_range(-250, +250)
	SpawnInTimer.start(TimerTime)
	
func _on_spawn_in_timer_timeout() -> void:
	var WeaponBox = WeaponsCrate.instantiate()
	add_child(WeaponBox)
	WeaponBox.position = SpawnMarker.position
