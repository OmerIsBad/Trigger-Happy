extends Node2D

var Knockback = 4750
var YKnockBack = 1000
var PushDirection
var YDirection
var DoIt = true

func _ready() -> void:
	$AnimatedSprite2D.play("Explode")
	await $AnimatedSprite2D.animation_finished
	queue_free()
	
func _process(delta: float) -> void:
	if $AnimatedSprite2D.frame == 3:
		DoIt = false


func _on_area_2d_body_entered(Thing: Node2D) -> void:
	if Thing.is_in_group("players") and DoIt:
		if Thing.global_position.x > global_position.x:
			PushDirection = 1
		else:
			PushDirection = -1
		if Thing.global_position.y > global_position.y:
			YDirection = 1
		else:
			YDirection = -1
		Thing.ApplyKnockback(Knockback, PushDirection)
		Thing.velocity.y += YKnockBack * YDirection
		
