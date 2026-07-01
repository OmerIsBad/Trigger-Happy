extends CharacterBody2D

@onready var WeaponHolderFlipperNode = $WeaponHolderFlipper
@onready var CoyoteTimerNode = $CoyoteTimer
@onready var AnimatedSprite = $AnimatedSprite2D

var CoyoteTime = 0.15
var CanJump = true

var CanDoubleJump = false
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
	
	#Start Coyote Timer if not on floor yuh
	if !is_on_floor() and CoyoteTimerNode.is_stopped():
		CoyoteTimerNode.start(CoyoteTime)
	
	#If he's on the floor we give em all jumping privilages 
	elif is_on_floor():
		CanJump = true
		CanDoubleJump = true
	
	#Stop Coyote Timer if player lands before it finishes and shi yuh
	if is_on_floor() and !CoyoteTimerNode.is_stopped():
		CoyoteTimerNode.stop()
	
	#Double Jump
	if Input.is_action_just_pressed(MoveJump):
		if !CanJump and CanDoubleJump:
			CanDoubleJump = false
			Jump()

	# Apply Acceeration if button in pressed
	if InputDirection == 1:
		velocity.x += Acceleration
	elif InputDirection == -1:
		velocity.x -= Acceleration
	
	
	
	#Apply Friction or Air Resistance if nothing is pressed
	if is_on_floor():
		#To prevent pingponging, reset to zero
		if InputDirection == 0.0 and abs(velocity.x) < Friction:
			velocity.x = 0
		elif InputDirection == 0.0 and velocity.x > 0.0:
			velocity.x -= Friction
		elif InputDirection == 0.0 and velocity.x < 0.0:
			velocity.x += Friction
	else:
		#to prevent pingponging, reset to zero
		if InputDirection == 0.0 and abs(velocity.x) < AirResistance:
			velocity.x = 0
		elif InputDirection == 0.0 and velocity.x > 0.0:
			velocity.x -= AirResistance
		elif InputDirection == 0.0 and velocity.x < 0.0:
			velocity.x += AirResistance
	
	
	#keep player from exceding top speed
	if velocity.x > TopSpeed:
		velocity.x = TopSpeed
	elif velocity.x < -TopSpeed:
		velocity.x = -TopSpeed
	
	#Jumpy
	if Input.is_action_just_pressed(MoveJump) and CanJump == true:
		Jump()
	
	#Upwards and downwards gravity
	if velocity.y >= 0 and !is_on_floor():
		velocity.y += DownGravity
	else:
		velocity.y += UpGravity
	
	#Turn Gun to direction
	WeaponHolderFlipperNode.scale.x = Direction

	#-----ANIMATIONS!-----
	if InputDirection == 0:
		AnimatedSprite.play("Idle")
	elif InputDirection == 1:
		AnimatedSprite.flip_h = true
		AnimatedSprite.play("Run")
	elif InputDirection == -1:
		AnimatedSprite.flip_h = false
		AnimatedSprite.play("Run")
	
	if !is_on_floor() and velocity.y > 0:
		AnimatedSprite.play("Fall")
	if !is_on_floor() and velocity.y < 0:
		AnimatedSprite.play("Jump")

	
	
	move_and_slide()
	

func Jump():
	velocity.y = -JumpForce
	CanJump = false
	
func ApplyKnockback(Knockback, PushDirection):
	print("Called! with knockback as: ", Knockback, "And direcion as: ", PushDirection)
	velocity.x += Knockback * PushDirection
	
	
func _on_coyote_timer_timeout() -> void:
	CanJump = false
