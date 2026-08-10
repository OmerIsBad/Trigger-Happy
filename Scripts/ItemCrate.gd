extends Node2D

@onready var CrateLifetime = $CrateLifetime
@onready var EquipSFX = $EquipSFX
@onready var Area = $Area2D
@onready var Sprite = $Sprite2D

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

var HasSpawned = false

func _ready() -> void:
	add_to_group("ItemCrates")
	Area.monitoring = false
	
	Sprite.modulate.a = 0.0
	
	var Tween = create_tween()
	Tween.set_loops(4)
	
	Tween.tween_property(Sprite, "modulate:a", 1.0, 0.25).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	Tween.tween_property(Sprite, "modulate:a", 0.0, 0.25).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	
	await Tween.finished
	
	Sprite.modulate.a = 1.0
	Area.monitoring = true

func _on_area_2d_body_entered(body: Node2D) -> void:
	if body.is_in_group("players"):
		
		# Getting rid of the old item and remembering it so we don't pick it
		var OldItem = null
		for ItemName in ItemNodeNames:
			if body.has_node(ItemName):
				OldItem = ItemName
				body.get_node(ItemName).queue_free()
		
		# Picking the item, making sure it's not the old one
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
