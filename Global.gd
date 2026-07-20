extends Node

var NormalTopSpeed
var NormalAcc
	
var PistolsList = [
	"Glock29",
	"Revolver",
	"Uzi",
	"GoldenEagle",
	"Musket"
	]

var ARList = [
	"AK47",
	"M16",
	"Scar",
	"BullPup",
	"Vector",
	"Ace",
	"TommyGun",
	"P90",
	]

var ShotGunList = [
	"PumpShotgun",
	"DoubleBarrel",
	"SawedOffShotty",
	"AutoShotgun",
	"CombatShotgun",
	]

var SniperList = [
	"AWMSniper",
	"BoltActionSniper",
	"CrossBow",
	"HeavySniper",
	]

var SpecialsList = [
	"Minigun",
	"RocketLauncher",
	"MissileLauncher",
	"GrenadeLauncher",
	]


@onready var TextBox = preload("res://Scenes/TextThrowUp.tscn")

func SummonText(Text: String, pos: Vector2, Size: int, Speed:int):
	var texty = TextBox.instantiate()
	texty.global_position = pos
	if Size != -1:
		texty.OutlineSize = Size/2
	texty.get_node("Text").text = Text
	if Speed != -1:
		texty.UpwardsBoostSpeed = Speed
	if Size != -1:
		texty.get_node("Text").add_theme_font_size_override("normal_font_size", Size)
	return texty



func CameraShake(ShakeStrength: float = 10.0, ShakeDuration: float = 0.2) -> void:
	var Camera = get_tree().current_scene.get_node("Camera2D")
	var OriginalOffset = Camera.offset
	
	var ShakeTween = create_tween()
	var Steps = 10
	var StepDuration = ShakeDuration / Steps
	
	for i in range(Steps):
#Decay strength over time so the shake tapers off type shi
		var CurrentStrength = ShakeStrength * (1.0 - float(i) / Steps)
		var RandomOffset = Vector2(
			randf_range(-CurrentStrength, CurrentStrength),
			randf_range(-CurrentStrength, CurrentStrength)
		)
		ShakeTween.tween_property(Camera, "offset", RandomOffset, StepDuration)
	
	ShakeTween.tween_property(Camera, "offset", OriginalOffset, StepDuration)
