extends Node2D
@onready var Area = $Area2D
@onready var SFX = $SFX
@onready var QuackSFX = $QuackSFX
var TotalKnockback = 3000
var PushDirection
var YDirection
var DoIt = true
var SmallerHitbox = false
var ExplosiveThingyReduction = 3
var ExplodeText = "BOOM!"
var ShieldStrength = 3
var DirectVictim: Node2D = null
var DirectHitUpwardForce = -1200.0
var DirectHitHorizontalForce = 4000.0

func _ready() -> void:
	if ExplodeText == "QUACK!":
		QuackSFX.play(0.8)
	SFX.play()
	SFX.reparent(get_tree().current_scene)
	SFX.finished.connect(SFX.queue_free)
	var TextLabel = global.SummonText(ExplodeText, global_position, 50, -1)
	global.CameraShake(50.0,0.3)
	get_tree().current_scene.add_child(TextLabel)
	
	if SmallerHitbox == true:
		Area.scale = Vector2(0.5,0.5)
	
	if DirectVictim != null and is_instance_valid(DirectVictim):
		ApplyDirectHit(DirectVictim)
	
	$AnimatedSprite2D.play("Explode")
	await $AnimatedSprite2D.animation_finished
	queue_free()

func ApplyDirectHit(Victim: Node2D) -> void:
	var LaunchDirection = sign(Victim.global_position.x - global_position.x)
	if LaunchDirection == 0:
		LaunchDirection = 1
	
	Victim.velocity.x += DirectHitHorizontalForce * LaunchDirection
	Victim.velocity.y = DirectHitUpwardForce

func _process(delta: float) -> void:
	if $AnimatedSprite2D.frame == 2:
		DoIt = false

func _on_area_2d_body_entered(Thing: Node2D) -> void:
	if Thing.is_in_group("players") and DoIt and !Thing.has_node("SpawnShield") and Thing != DirectVictim:
		var HasShield = Thing.has_node("ShieldManager") and Thing.get_node("ShieldManager").has_node("Shield")
		print("Does he have a manager: " + str(Thing.has_node("ShieldManager")))
		#Check why this isnt working
		if Thing.has_node("ShieldManager"):
			print("Does he have a shield: " + str(Thing.has_node("Shield")))
		var DiffDirection = (Thing.global_position - global_position).normalized()
		var RawVerticalKnockback = DiffDirection.y * TotalKnockback
		var MaxVerticalKnockback = 400.0
		
		var FinalVerticalKnockback = RawVerticalKnockback
		var VerticalOverflow = 0.0
		
		#Only clamp downward force, and only if the player is grounded (wasted force otherwise)
		if RawVerticalKnockback > 0 and Thing.is_on_floor():
			FinalVerticalKnockback = min(RawVerticalKnockback, MaxVerticalKnockback)
			VerticalOverflow = RawVerticalKnockback - FinalVerticalKnockback
		
		var HorizontalSign = sign(DiffDirection.x)
		if HorizontalSign == 0:
			HorizontalSign = 1
		
		if !HasShield:
			Thing.velocity.x += (DiffDirection.x * TotalKnockback) + (VerticalOverflow * HorizontalSign)
			Thing.velocity.y += FinalVerticalKnockback
		else:
			Thing.velocity.x += ((DiffDirection.x * TotalKnockback) + (VerticalOverflow * HorizontalSign)) / ShieldStrength
			Thing.velocity.y += FinalVerticalKnockback / ShieldStrength
	
	
	
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
