extends Node2D

@onready var BulletLifeTimer = $BulletLifeTimer
@onready var TrailNode = $Trail
var TrailLength = 2
var Speed
var Lifetime
var Knockback
var Direction
var PrevPos
var FirstPos

var ShotByGun

var PlayerHit
var PistolTextOdds = 4 #One in whatever

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
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
	var Result = SpaceState.intersect_ray(Query)
	
	
	TrailNode.add_point(global_position)
	if TrailNode.get_point_count() > TrailLength:
		TrailNode.remove_point(0)
	
	if Result:
		var body = Result.collider
		if body.is_in_group("players"):
			PlayerHit = body
			ManageTextThrow()
			body.LastShot = Time.get_ticks_msec()
			body.ApplyKnockback(Knockback, Direction)
			queue_free()

func _on_bullet_life_timer_timeout() -> void:
	queue_free()

func ManageTextThrow():
	if global.ShotGunList.has(ShotByGun):
		var PwnedText = global.SummonText("Pwned!", global_position, 20, -1)
		get_tree().current_scene.add_child(PwnedText)
	if global.SniperList.has(ShotByGun):
		var SnipedText = global.SummonText("Sniped!", global_position, 20, -1)
		get_tree().current_scene.add_child(SnipedText)
