extends Node2D

@onready var BulletLifeTimer = $BulletLifeTimer

var Speed
var Lifetime
var Knockback
var Direction

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	BulletLifeTimer.start(Lifetime)


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	position.x += Speed * Direction


func _on_bullet_life_timer_timeout() -> void:
	queue_free()
