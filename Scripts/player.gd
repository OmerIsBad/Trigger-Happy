extends CharacterBody2D

@onready var WeaponHolderFlipperNode = $WeaponHolderFlipper

var Acceleration = 40.0
var TopSpeed = 500.0
var Friction = 25
var AirResistance = 15
var UpGravity = 40
var DownGravity = 60
var JumpForce = 1000
var MoveLeft
var MoveRight
var MoveJump
var Direction = -1.0 
var InputDirection

func IdentifyPlayer():
	if name == "Player1":
		MoveLeft = "LEFT"
		MoveRight = "RIGHT"
		MoveJump = "JUMP"
	elif name == "Player2":
		MoveLeft = "LEFT_2"
		MoveRight = "RIGHT_2"
		MoveJump = "JUMP_2"

func _ready() -> void:
	IdentifyPlayer()

func _physics_process(delta: float) -> void:
	InputDirection = Input.get_axis(MoveLeft, MoveRight)
	if InputDirection != 0:
		Direction = InputDirection

	# Apply Acceeration if button in pressed
	if InputDirection == 1:
		velocity.x += Acceleration
	elif InputDirection == -1:
		velocity.x -= Acceleration
	
	
	
	#Apply Friction or Air Resistance if nothing is pressed
	if is_on_floor():
		if InputDirection == 0.0 and abs(velocity.x) < Friction:
			velocity.x = 0
		elif InputDirection == 0.0 and velocity.x > 0.0:
			velocity.x -= Friction
		elif InputDirection == 0.0 and velocity.x < 0.0:
			velocity.x += Friction
	
	
	#keep player from exceding top speed
	if velocity.x > TopSpeed:
		velocity.x = TopSpeed
	elif velocity.x < -TopSpeed:
		velocity.x = -TopSpeed
	
	#Jumpy
	if Input.is_action_just_pressed(MoveJump) and is_on_floor() == true:
		velocity.y = -JumpForce
	
	#Upwards and downwards gravity
	if velocity.y >= 0 and is_on_floor() != true:
		velocity.y += DownGravity
	else:
		velocity.y += UpGravity
	
	#Turn Gun to direction
	WeaponHolderFlipperNode.scale.x = Direction

	move_and_slide()
	
	
