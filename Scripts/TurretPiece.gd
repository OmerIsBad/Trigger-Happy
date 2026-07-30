extends Node2D

var PieceIndex 
@onready var Sprite = $AnimatedSprite2D

var WhyVelocity
var ExVelocity

var RandomBound = 10
var Degradation = 0.25
var Gravity = 1

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	Sprite.play(PieceIndex)
	WhyVelocity = randi_range(-RandomBound, 0)
	ExVelocity = randi_range(RandomBound, -RandomBound) +5


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	position.x += ExVelocity
	position.y += WhyVelocity
	
	if ExVelocity > 0:
		ExVelocity -= Degradation
	elif ExVelocity < 0:
		ExVelocity += Degradation
	else:
		ExVelocity = 0
	
	WhyVelocity += Gravity
