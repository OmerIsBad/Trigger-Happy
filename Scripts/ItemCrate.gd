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

var ItemNodeNames = {
	"Dash": "DashManager",
	"Shield": "ShieldManager",
	"Mines": "MinePlacerItem",
	"DuckBomb": "DuckBombManager",
	"Grenades": "GrenadeManager",
	"SuperSpeed": "SpeedManager",
	"Portals": "PortalManager",
	"OSL": "OSL",
	"JetPack": "JetPack",
	"Turret": "TurretManager"
}

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

		#Find and remove the player's current item
		var OldItem = null
		for ItemName in ItemNodeNames:
			var NodeName = ItemNodeNames[ItemName]
			if body.has_node(NodeName):
				print("Bro already has " + ItemName)
				OldItem = ItemName
				body.get_node(NodeName).queue_free()
				
		# Pick a new item that isn't the old item
		var ChosenItem = Items.keys().pick_random()
		
		if OldItem != null:
			while ChosenItem == OldItem:
				ChosenItem = Items.keys().pick_random()
		
		var Item = Items[ChosenItem].instantiate()
		body.add_child(Item)
		get_parent().RestartCrateShenanigans()
		
		var PopUpText = global.SummonText(ChosenItem, global_position,-1, -1)
		get_tree().current_scene.add_child(PopUpText)
		
		EquipSFX.play()
		EquipSFX.reparent(get_tree().current_scene)
		EquipSFX.finished.connect(EquipSFX.queue_free)
		
		queue_free()


func _on_crate_lifetime_timeout() -> void:
	get_parent().RestartCrateShenanigans()
	queue_free()
