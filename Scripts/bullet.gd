extends Node2D

@onready var BulletLifeTimer = $BulletLifeTimer

var Speed
var Lifetime
var Knockback
var Direction

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	BulletLifeTimer.start(Lifetime)

func _on_hit_box_body_entered(body: Node2D) -> void:
	if body.is_in_group("players"):
		body.ApplyKnockback(Knockback,Direction)
		queue_free()

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _physics_process(delta: float) -> void:
	var prev_pos = position
	position.x += Speed * Direction 
	var space_state = get_world_2d().direct_space_state
	var query = PhysicsRayQueryParameters2D.create(prev_pos, position)
	var result = space_state.intersect_ray(query)
	if result:
		var body = result.collider
		if body.is_in_group("players"):
			body.ApplyKnockback(Knockback, Direction)
		queue_free()


func _on_bullet_life_timer_timeout() -> void:
	queue_free()
