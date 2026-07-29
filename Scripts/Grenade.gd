extends RigidBody2D

var ExplosionScene = preload("res://Scenes/ExplosionAir.tscn")
@onready var Countdown = $Timer
@onready var FlashTimer = $FlashTimer
@onready var Sprite = $AnimatedSprite2D
@onready var TrailNode = $Trail
var TrailLength = 20
var TrailPaused = false

var Direction = -1
var Speed = 600
var UpwardsForce = -650
var LastSecond = 0  

var PercentForce = 0.25

var ShotByGun


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	add_to_group("Bullets")
	add_to_group("ExplosiveThingiesThatShouldAlsoBeMovedByExplosions")
	apply_impulse(Vector2((Speed*PercentForce) * Direction, (UpwardsForce*PercentForce)))
	apply_torque((-10000.0 * Direction)+ randi_range(-2500, 2500))
	
func _process(delta: float) -> void:
	var CurrentSecond = floor(Countdown.time_left)
	if CurrentSecond != LastSecond:
		Sprite.modulate = Color(1, 0, 0, 1)
		LastSecond = CurrentSecond
		FlashTimer.start()
	
	if !TrailPaused:
		TrailNode.add_point(global_position)
		if TrailNode.get_point_count() > TrailLength:
			TrailNode.remove_point(0)
	
	if TrailPaused:
		TrailPaused = false

func _on_timer_timeout() -> void:
	var Explosion = ExplosionScene.instantiate()
	Explosion.global_position = global_position
	get_tree().current_scene.add_child(Explosion)
	queue_free()


func _on_flash_timer_timeout() -> void:
	Sprite.modulate = Color(1, 1, 1, 1)

func EmptyTrail():
	TrailPaused = true
	TrailNode.clear_points()
