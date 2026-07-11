extends Node2D
@onready var TrailNode = $Trail
@onready var TrailingEnd = $TrailingEnd
var ExplosionAir = preload("res://Scenes/ExplosionAir.tscn")
var Speed
var Lifetime
var Knockback
var Direction
var PrevPos
var FirstPos
var ShotBy
var TargetPlayer
var TrailLength = 15
var IdealDirectionVector
var Step
var TurnRate = 3  # radians per second
var HasFuel = true
var Velocity = Vector2.ZERO
var Gravity = 2500.0     
var Drag = 1.0       

func _ready() -> void:
	FirstPos = position
	TrailNode.add_point(FirstPos)
	
	Direction = Vector2(Direction, 0)
	
	var DistanceToClosestPlayer = 9999999999.999
	for Player in get_tree().get_nodes_in_group("players"):
		if Player.name != ShotBy:
			if position.distance_to(Player.position) < DistanceToClosestPlayer:
				DistanceToClosestPlayer = position.distance_to(Player.position)
				TargetPlayer = Player

func _physics_process(delta: float) -> void:
	
	if HasFuel:
		IdealDirectionVector = (TargetPlayer.position - position).normalized()
		
		var NewAngle = rotate_toward(Direction.angle(), IdealDirectionVector.angle(), TurnRate * delta)
		Direction = Vector2.from_angle(NewAngle)
		
		Step = Direction * Speed * delta
		
		PrevPos = position
		position += Step
		
		#Keep Velocity up to date while fueled, so it's ready the instant fuel runs out
		Velocity = Direction * Speed
		
		rotation = Direction.angle()
		
				#---TRAIL--- 
		TrailNode.add_point(TrailingEnd.global_position)
		if TrailNode.get_point_count() > TrailLength:
			TrailNode.remove_point(0)
		
	else:
		# ouuu shit we outta fuel
		Velocity.y += Gravity * delta
		Velocity *= Drag
		
		PrevPos = position
		position += Velocity * delta
	


func _on_bullet_life_timer_timeout() -> void:
	queue_free()

func _on_hit_box_body_entered(body: Node2D) -> void:
	if body.is_in_group("players") and body.name != ShotBy:
		if position.x - PrevPos.x > 0:
			position.x = body.position.x - 10
		else:
			position.x = body.position.x + 10
		var Explosion = ExplosionAir.instantiate()
		Explosion.global_position = global_position
		get_tree().current_scene.add_child(Explosion)
		queue_free()

func _on_hit_box_area_entered(area: Area2D) -> void:
	if area.get_parent().name == "Missile":
		area.get_parent().queue_free()
		var Explosion = ExplosionAir.instantiate()
		Explosion.global_position = global_position
		Explosion.SmallerHitbox = true
		get_tree().current_scene.add_child(Explosion)
		queue_free()

func _on_fuel_timer_timeout() -> void:
	HasFuel = false
	TrailNode.clear_points()
