extends Node2D
@onready var Area = $Area2D

var TotalKnockback = 3000

var PushDirection
var YDirection
var DoIt = true
var SmallerHitbox = false
var ExplosiveThingyReduction = 3

func _ready() -> void:
	var TextLabel = global.SummonText("BOOM!", global_position, 50, -1)
	global.CameraShake(50.0,0.3)
	get_tree().current_scene.add_child(TextLabel)
	
	if SmallerHitbox == true:
		Area.scale = Vector2(0.5,0.5)
	$AnimatedSprite2D.play("Explode")
	await $AnimatedSprite2D.animation_finished
	queue_free()
	
func _process(delta: float) -> void:
	if $AnimatedSprite2D.frame == 2:
		DoIt = false


func _on_area_2d_body_entered(Thing: Node2D) -> void:
	if Thing.is_in_group("players") and DoIt:
	#This code is a fucking mess but it works so dont touch it
		
		var DiffDirection = (Thing.global_position - global_position).normalized()
		var RawVerticalKnockback = DiffDirection.y * TotalKnockback
		var MaxVerticalKnockback = 400.0 
		var ClampedVerticalKnockback = clamp(RawVerticalKnockback, -MaxVerticalKnockback, MaxVerticalKnockback)
		var VerticalOverflow = abs(RawVerticalKnockback) - abs(ClampedVerticalKnockback)
		var HorizontalSign = sign(DiffDirection.x)
		if HorizontalSign == 0:
			HorizontalSign = 1  
		Thing.velocity.x += (DiffDirection.x * TotalKnockback) + (VerticalOverflow * HorizontalSign)
		Thing.velocity.y += ClampedVerticalKnockback
		
	
	
	
	if Thing.is_in_group("ExplosiveThingiesThatShouldAlsoBeMovedByExplosions") and DoIt:
		var DiffDirection = (Thing.global_position - global_position).normalized()
		var RawVerticalKnockback = DiffDirection.y * TotalKnockback
		var MaxVerticalKnockback = 400.0 
		var ClampedVerticalKnockback = clamp(RawVerticalKnockback, -MaxVerticalKnockback, MaxVerticalKnockback)
		var VerticalOverflow = abs(RawVerticalKnockback) - abs(ClampedVerticalKnockback)
		var HorizontalSign = sign(DiffDirection.x)
		var KnockbackVector = Vector2(
			(DiffDirection.x * TotalKnockback) + (VerticalOverflow * HorizontalSign),
			ClampedVerticalKnockback
		)
		Thing.apply_impulse(KnockbackVector / ExplosiveThingyReduction)

		
		
