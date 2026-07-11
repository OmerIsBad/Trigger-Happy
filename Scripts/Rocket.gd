extends Node2D
@onready var BulletLifeTimer = $RocketLifeTimer
@onready var TrailNode = $Trail
var ExplosionAir = preload("res://Scenes/ExplosionAir.tscn")
var Speed
var Lifetime
var Knockback
var Direction
var PrevPos
var FirstPos
var TrailLength = 5
# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	BulletLifeTimer.start(Lifetime)
	FirstPos = position
	TrailNode.add_point(FirstPos)
# Called every frame. 'delta' is the elapsed time since the previous frame.
func _physics_process(delta: float) -> void:
	PrevPos = position
	
	position.x += Speed * Direction 
	var SpaceState = get_world_2d().direct_space_state
	var Query = PhysicsRayQueryParameters2D.create(PrevPos, position)
	var Result = SpaceState.intersect_ray(Query)
	
	
	TrailNode.add_point(global_position)
	if TrailNode.get_point_count() > TrailLength:
		TrailNode.remove_point(0)
	
	if Result:
		var body = Result.collider
		if body.is_in_group("players"):
#Setting the rockets position back to where it SHOULDVE collided
#To prevent incorrect knockback direction from explosions
			if Direction == 1:
				position.x = body.position.x - 10
			else:
				position.x = body.position.x + 10
			var Explosion = ExplosionAir.instantiate()
			Explosion.global_position = global_position
			get_tree().current_scene.add_child(Explosion)
			queue_free()
func _on_bullet_life_timer_timeout() -> void:
	queue_free()
