extends Node2D
@onready var Area = $Area2D

var TotalKnockback = 3000

var PushDirection
var YDirection
var DoIt = true
var SmallerHitbox = false


func _ready() -> void:
	if SmallerHitbox == true:
		Area.scale = Vector2(0.5,0.5)
	$AnimatedSprite2D.play("Explode")
	await $AnimatedSprite2D.animation_finished
	queue_free()
	
func _process(delta: float) -> void:
	if $AnimatedSprite2D.frame == 3:
		DoIt = false


func _on_area_2d_body_entered(Thing: Node2D) -> void:
	if Thing.is_in_group("players") and DoIt:
		#This code is a fucking mess but it works
		
		var DiffDirection = (Thing.global_position - global_position).normalized()

		#How strong the raw vertical push would be if uncapped
		var RawVerticalKnockback = DiffDirection.y * TotalKnockback

		#Capping vertical knockback to a max, in either direction (up or down)
		var MaxVerticalKnockback = 400.0  # tune this to taste
		var ClampedVerticalKnockback = clamp(RawVerticalKnockback, -MaxVerticalKnockback, MaxVerticalKnockback)

		#Whatever got cut off by the clamp is "leftover" energy to redirect into X
		var VerticalOverflow = abs(RawVerticalKnockback) - abs(ClampedVerticalKnockback)

		#Figure out which horizontal side the explosion is already leaning toward,
		#so the leftover energy pushes further in that same direction
		var HorizontalSign = sign(DiffDirection.x)
		if HorizontalSign == 0:
			HorizontalSign = 1  #fallback if explosion is dead-center horizontally, pick a default side

		Thing.velocity.x += (DiffDirection.x * TotalKnockback) + (VerticalOverflow * HorizontalSign)
		Thing.velocity.y += ClampedVerticalKnockback
		
		
		
