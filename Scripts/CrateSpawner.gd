extends Node2D
@onready var SpawnInTimer = $SpawnInTimer
@onready var SpawnMarker = $SpawnMarker
var WeaponsCrate = preload("res://Scenes/WeaponCrate.tscn")
var ItemCrate = preload("res://Scenes/ItemCrate.tscn")
var MaxCrates: int = 2
var MinSpawnDelay: int = 10
var MaxSpawnDelay: int = 30
var SpawnJitterRange: int = 150
var CrateGroupName: String = "WeaponCrates"
var ItemCrateGroupName: String = "ItemCrates"
var OriginPosition: Vector2
var ItemBoxChance = 4 # One in X chance type shi

var SpawningWeaponCrateSprite = preload("res://Assets/WeaponCrate.png")
var SpawningItemCrate = preload("res://Assets/RustyItemCrate.png")

func _ready() -> void:
	OriginPosition = global_position
	RestartCrateShenanigans()

func RestartCrateShenanigans() -> void:
	var timer_time = randi_range(MinSpawnDelay, MaxSpawnDelay)
	global_position.x = OriginPosition.x + randi_range(-SpawnJitterRange, SpawnJitterRange)
	SpawnInTimer.start(timer_time)

func _on_spawn_in_timer_timeout() -> void:
	var TotalCrates = get_tree().get_nodes_in_group(CrateGroupName).size() + get_tree().get_nodes_in_group(ItemCrateGroupName).size()
	
	if TotalCrates < MaxCrates:
		var CrateToSpawn
		if randi_range(1, ItemBoxChance) == 1:
			CrateToSpawn = WeaponsCrate.instantiate()
		else:
			CrateToSpawn = ItemCrate.instantiate()
		
		add_child(CrateToSpawn)
		CrateToSpawn.position = SpawnMarker.position
	else:
		RestartCrateShenanigans()
