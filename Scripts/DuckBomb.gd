extends Node2D

var ExplosionScene = preload("res://Scenes/MineExplosion.tscn")
@onready var DuckSprite = $AnimatedSprite2D
@onready var ShieldImmunity = $ShieldImmunity
@onready var LeftCast = $LeftCast
@onready var RightCast = $RightCast

var Activated = false
var Stepper

var Speed = 2
var Direction = 1

func _process(delta: float) -> void:
	var IsNearRightLedge = false
	var IsNearLeftLedge = false
	if RightCast.is_colliding():
		var body = RightCast.get_collider()
		if body is not StaticBody2D:
			IsNearRightLedge = true
	else:
		IsNearRightLedge = true
		
	if LeftCast.is_colliding():
		var body = LeftCast.get_collider()
		if body is not StaticBody2D:
			IsNearLeftLedge = true
	else:
		IsNearLeftLedge = true

	if IsNearRightLedge and Direction == 1:
		Direction = -1
	elif IsNearLeftLedge and Direction == -1:
		Direction = 1
	
	
	position.x += Speed * Direction
	
	if Direction == 1:
		DuckSprite.flip_h = true
	else:
		DuckSprite.flip_h = false


func _on_area_2d_body_entered(body: Node2D) -> void:
	if body.is_in_group("players") and Activated:
		Activated = false
		
		body.ShieldMaskOverride = true
		body.set_collision_mask_value(7, false)
		
		Stepper = body
		ShieldImmunity.start()

		
		var Explosion = ExplosionScene.instantiate()
		
		Explosion.global_position = global_position
		Explosion.ExplodeText = "QUACK!"
		Explosion.DirectVictim = body
		
		get_tree().current_scene.add_child(Explosion)



func _on_start_up_timer_timeout() -> void:
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
