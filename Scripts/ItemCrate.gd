extends Node2D

@onready var CrateLifetime = $CrateLifetime
@onready var EquipSFX = $EquipSFX


var Items = {
		"Dash": preload("res://Scenes/DashManager.tscn"),
		"Shield": preload("res://Scenes/ShieldManager.tscn"),
		"Mines": preload("res://Scenes/MinePlacerItem.tscn"),
		"DuckBomb": preload("res://Scenes/DuckBombManager.tscn"),
		"Grenades": preload("res://Scenes/GrenadeManager.tscn"),
		"SuperSpeed": preload("res://Scenes/SpeedManager.tscn"),
		"Portals": preload("res://Scenes/PortalManager.tscn"),
		"OSL": preload("res://Scenes/OSL.tscn"),
		"JetPack": preload("res://Scenes/JetPack.tscn"),
		"Turret": preload("res://Scenes/TurretManager.tscn")
		}
		
var ItemNodeNames = ["DashManager", "DuckBombManager", "GrenadeManager", "JetPack", "MinePlacerItem", "PortalManager", "TurretManager", "SpeedManager", "ShieldManager", "OSL"]

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	add_to_group("ItemCrates")
	
	
func _on_area_2d_body_entered(body: Node2D) -> void:
	if body.is_in_group("players"):
		
		#Getting rid of the old item and rememvering it so we dont pick it
		var OldItem = null
		for ItemName in ItemNodeNames:
			if body.has_node(ItemName):
				print("YOOO SHIT THIS MF GREEDY ASH TRYNNA HAVE 2 ITEMS")
				OldItem = ItemName
				body.get_node(ItemName).queue_free()
		
		
		#Picking the item, making sure its not the old one IF we even had an old one
		var ChosenItem = Items.keys().pick_random()
		if OldItem != null:
			while true:
				if ChosenItem == OldItem:
					ChosenItem = Items.keys().pick_random()
				else:
					break
		
		
		var Item = Items[ChosenItem].instantiate()
		body.add_child(Item)
		
		get_parent().RestartCrateShenanigans()
		
		EquipSFX.play()
		EquipSFX.reparent(get_tree().current_scene)
		EquipSFX.finished.connect(EquipSFX.queue_free)
		
		queue_free()


func _on_crate_lifetime_timeout() -> void:
	get_parent().RestartCrateShenanigans()
	queue_free()
