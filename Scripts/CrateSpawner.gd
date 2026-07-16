extends Node2D

@onready var SpawnInTimer = $SpawnInTimer
@onready var SpawnMarker = $SpawnMarker

var WeaponsCrate = preload("res://Scenes/WeaponCrate.tscn")

var MaxCrates: int = 2
var MinSpawnDelay: int = 10
var MaxSpawnDelay: int = 60
var SpawnJitterRange: int = 150
var CrateGroupName: String = "WeaponCrates"
var OriginPosition: Vector2

func _ready() -> void:
	OriginPosition = global_position
	RestartCrateShenanigans()

func RestartCrateShenanigans() -> void:
	var timer_time = randi_range(MinSpawnDelay, MaxSpawnDelay)
	global_position.x = OriginPosition.x + randi_range(-SpawnJitterRange, SpawnJitterRange)
	SpawnInTimer.start(timer_time)

func _on_spawn_in_timer_timeout() -> void:
	var number_of_crates = get_tree().get_nodes_in_group(CrateGroupName).size()
	if number_of_crates < MaxCrates:
		var weapon_box = WeaponsCrate.instantiate()
		add_child(weapon_box)
		weapon_box.position = SpawnMarker.position
	else:
		RestartCrateShenanigans()
