extends Node2D
@onready var Area = $Area2D
@onready var SFX = $SFX

var TotalKnockback = 3000

var PushDirection
var YDirection
var DoIt = true
var SmallerHitbox = false
var ExplosiveThingyReduction = 3

var ShieldStrength = 3

func _ready() -> void:
	SFX.play()
	SFX.reparent(get_tree().current_scene)
	SFX.finished.connect(SFX.queue_free)
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
	if Thing.is_in_group("players") and DoIt and !Thing.has_node("SpawnShield"):
	#This code is a fucking mess but it works so dont touch it
		var HasShield = Thing.has_node("ShieldManager") and Thing.get_node("ShieldManager").has_node("Shield")
			
		var DiffDirection = (Thing.global_position - global_position).normalized()
		var RawVerticalKnockback = DiffDirection.y * TotalKnockback
		var MaxVerticalKnockback = 400.0 
		var ClampedVerticalKnockback = clamp(RawVerticalKnockback, -MaxVerticalKnockback, MaxVerticalKnockback)
		var VerticalOverflow = abs(RawVerticalKnockback) - abs(ClampedVerticalKnockback)
		var HorizontalSign = sign(DiffDirection.x)
		if HorizontalSign == 0:
			HorizontalSign = 1  
			
		if !HasShield:
			Thing.velocity.x += (DiffDirection.x * TotalKnockback) + (VerticalOverflow * HorizontalSign)
			Thing.velocity.y += ClampedVerticalKnockback
		
		else: 
			Thing.velocity.x += ((DiffDirection.x * TotalKnockback) + (VerticalOverflow * HorizontalSign)) / ShieldStrength
			Thing.velocity.y += ClampedVerticalKnockback/ShieldStrength
		
	
	
	
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
		
	if Thing.is_in_group("Turrets"):
		Thing.Shatter()
		Thing.queue_free()
		
		
