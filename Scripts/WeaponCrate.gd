extends Node2D

@onready var CrateLifetime = $CrateLifetime
@onready var EquipSFX = $EquipSFX
@onready var Sprite = $Sprite2D
@onready var Area = $Area2D

var Weapons = {
	# Pistols
	"Revolver": preload("res://Scenes/Revolver.tscn"),
	"Uzi": preload("res://Scenes/Uzi.tscn"),
	"GoldenEagle": preload("res://Scenes/GoldenEagle.tscn"),
	"Musket": preload("res://Scenes/Musket.tscn"),

	# Assault Rifles
	"AK47": preload("res://Scenes/AK47.tscn"),
	"M16": preload("res://Scenes/M16.tscn"),
	"Scar": preload("res://Scenes/Scar.tscn"),
	"BullPup": preload("res://Scenes/BullPup.tscn"),
	"Vector": preload("res://Scenes/Vector.tscn"),
	"Ace": preload("res://Scenes/Ace.tscn"),
	"TommyGun": preload("res://Scenes/TommyGun.tscn"),
	"P90": preload("res://Scenes/P90.tscn"),

	# ShotGuns
	"PumpShotgun": preload("res://Scenes/PumpShotgun.tscn"),
	"DoubleBarrel": preload("res://Scenes/DoubleBarrel.tscn"),
	"SawedOffShotty": preload("res://Scenes/SawedOffShotty.tscn"),
	"AutoShotgun": preload("res://Scenes/AutoShotgun.tscn"),
	"CombatShotgun": preload("res://Scenes/CombatShotgun.tscn"),

	# Snipers
	"AWMSniper": preload("res://Scenes/AWMSniper.tscn"),
	"BoltAction": preload("res://Scenes/BoltAction.tscn"),
	"CrossBow": preload("res://Scenes/CrossBow.tscn"),
	"HeavySniper": preload("res://Scenes/HeavySniper.tscn"),

	# Specials
	"Minigun": preload("res://Scenes/Minigun.tscn"),
	"GrenadeLauncher": preload("res://Scenes/GrenadeLauncher.tscn"),
	"RocketLauncher": preload("res://Scenes/RocketLauncher.tscn"),
	"MissileLauncher": preload("res://Scenes/MissileLauncher.tscn")
}

func _ready() -> void:
	add_to_group("WeaponCrates")

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
		var WeaponHolder = body.get_node("Hand/WeaponHolder")
		var OldGun = WeaponHolder.get_child(0).name
		WeaponHolder.get_child(0).queue_free()

		var ChosenGun = Weapons.keys().pick_random()
		while true:
			if ChosenGun == OldGun:
				ChosenGun = Weapons.keys().pick_random()
			else:
				break

		var NewGun = Weapons[ChosenGun].instantiate()
		WeaponHolder.add_child(NewGun)

		# Fixing the missing spaces
		# This is a stupid solution but it works
		var SpacedGunName = ""

		if ChosenGun == "AWMSniper":
			SpacedGunName = "AWM Sniper"
		elif ChosenGun == "AK47":
			SpacedGunName = "AK47"
		else:
			for letter in ChosenGun:
				if letter == letter.to_upper() and letter != letter.to_lower():
					if SpacedGunName != "":
						SpacedGunName += " "
				SpacedGunName += letter

		print(SpacedGunName)

		var GunNameText = global.SummonText(str(SpacedGunName), global_position, -1, -1)
		get_tree().current_scene.add_child(GunNameText)

		print("Erased Gun: ", OldGun, " And Given Gun: ", ChosenGun)

		get_parent().RestartCrateShenanigans()

		EquipSFX.play()
		EquipSFX.reparent(get_tree().current_scene)
		EquipSFX.finished.connect(EquipSFX.queue_free)

		queue_free()


func _on_crate_lifetime_timeout() -> void:
	get_parent().RestartCrateShenanigans()
	queue_free()
