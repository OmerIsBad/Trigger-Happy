extends Node2D

@onready var HitSFX: AudioStreamPlayer = $HitSFX
@onready var BulletLifeTimer = $BulletLifeTimer
@onready var TrailNode = $Trail
@onready var TurretHitSFX = $TurretHitSFX


var TrailLength = 2
var Speed
var Lifetime
var Knockback
var Direction
var PrevPos
var FirstPos

var ShotByGun

var PlayerHit

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	add_to_group("Bullets")
	BulletLifeTimer.start(Lifetime)
	FirstPos = position
	TrailNode.add_point(FirstPos)

func _on_hit_box_body_entered(body: Node2D) -> void:
	if body.is_in_group("players"):
		body.ApplyKnockback(Knockback,Direction)
		queue_free()

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _physics_process(delta: float) -> void:
	PrevPos = position
	
	position.x += Speed * Direction 
	var SpaceState = get_world_2d().direct_space_state
	var Query = PhysicsRayQueryParameters2D.create(PrevPos, position)
	Query.collide_with_areas = true
	var Result = SpaceState.intersect_ray(Query)
	
	TrailNode.add_point(global_position)
	if TrailNode.get_point_count() > TrailLength:
		TrailNode.remove_point(0)
	
	
	if Result:
		var body = Result.collider
		if body.is_in_group("players") or body.is_in_group("ShootingDummys"):
			if !body.has_node("SpawnShield"):
				PlayerHit = body
				ManageTextThrow()
				body.LastShot = Time.get_ticks_msec()
				body.ApplyKnockback(Knockback, Direction)
				
				var PitchMin = 0.20
				var PitchMax = 0.25
				
				HitSFX.pitch_scale = randf_range(PitchMin, PitchMax)
				
				HitSFX.play()
				HitSFX.reparent(get_tree().current_scene)
				HitSFX.finished.connect(HitSFX.queue_free)
				queue_free()
			else:
				queue_free()
		
		elif body.is_in_group("Turrets"):
			var KnockBackToTimeRate = 500 #How much KB is 1 second
			var TimeDamage = Knockback / float(KnockBackToTimeRate)
			
			var NewTime = max(0.001, body.LifeTimer.time_left - TimeDamage)
			body.LifeTimer.start(NewTime)
			
			var PitchMin = 1.8
			var PitchMax = 2.8
			
			TurretHitSFX.pitch_scale = randf_range(PitchMin, PitchMax)
			TurretHitSFX.play()
			TurretHitSFX.reparent(get_tree().current_scene)
			TurretHitSFX.finished.connect(TurretHitSFX.queue_free)
			
			queue_free()
		
		#elif body.is_in_group("ShootingDummys"):
			#pass

			
		elif body.name == "Shield":
			var PitchMin = 1.8
			var PitchMax = 2.8
			TurretHitSFX.pitch_scale = randf_range(PitchMin, PitchMax)
			TurretHitSFX.play()
			TurretHitSFX.reparent(get_tree().current_scene)
			TurretHitSFX.finished.connect(TurretHitSFX.queue_free)
			queue_free()
		
		elif body.get_parent().is_in_group("Portals"):
			TrailNode.clear_points()
			for Portal in get_tree().get_nodes_in_group("Portals"):
				if Portal.name != body.get_parent().name:
					if Direction == 1:
						Portal.TeleportToMarker("Right", self)
					else:
						Portal.TeleportToMarker("Left", self)


func _on_bullet_life_timer_timeout() -> void:
	queue_free()

func ManageTextThrow():
	if ShotByGun == "AWM_Sniper":
		ShotByGun = "AWMSniper"
	if ShotByGun == "Heavy_Sniper":
		ShotByGun = "HeavySniper"
	print(ShotByGun)
	if global.ShotGunList.has(ShotByGun):
		var PwnedText = global.SummonText("Pwned!", global_position, -1, -1)
		get_tree().current_scene.add_child(PwnedText)
	if global.SniperList.has(ShotByGun):
		var SnipedText = global.SummonText("Sniped!", global_position, -1, -1)
		get_tree().current_scene.add_child(SnipedText)
