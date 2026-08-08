extends Node2D

var ExplosionScene = preload("res://Scenes/MineExplosion.tscn")
@onready var MineSprite = $AnimatedSprite2D
@onready var ShieldImmunity = $ShieldImmunity
@onready var PlaceDownSFX: AudioStreamPlayer2D = $PlaceDownSFX
@onready var BeepSFX: AudioStreamPlayer2D = $BeepSFX

var Activated = false
var Stepper

func _ready() -> void:
	PlaceDownSFX.play()

func _process(delta: float) -> void:
	if MineSprite.frame == 1:
		BeepSFX.play(1)

func _on_area_2d_body_entered(body: Node2D) -> void:
	if body.is_in_group("players") and Activated:
		Activated = false
		Stepper = body
		
		var Explosion = ExplosionScene.instantiate()
		Explosion.global_position = global_position
		Explosion.DirectVictim = body
		get_tree().current_scene.add_child(Explosion)
		
		queue_free()



func _on_start_up_timer_timeout() -> void:
	MineSprite.play("Blink")
	Activated = true


func _on_shield_immunity_timeout() -> void:
	Stepper.set_collision_mask_value(7, true)
	Stepper.ShieldMaskOverride = false
	queue_free()

func PrintCollisionInfo(node: CollisionObject2D) -> void:
	print("--- ", node.name, " ---")
	for i in range(1, 21):  
		if node.get_collision_layer_value(i):
			print("  Layer ", i, ": ON")
		if node.get_collision_mask_value(i):
			print("  Mask ", i, ": ON")
