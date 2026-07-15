extends CharacterBody2D

@onready var HandNode = $Hand
@onready var WeaponHolderNode = $Hand/WeaponHolder
@onready var CoyoteTimerNode = $CoyoteTimer
@onready var AnimatedSprite = $AnimatedSprite2D

var CoyoteTime = 0.15
var CanJump = true

var CanDoubleJump = false
var Acceleration = 40.0
var TopSpeed = 500.0
var Friction = 25
var ExtremeSpeedFriction = 80
var AirResistance = 15
var UpGravity = 40
var DownGravity = 60
var JumpForce = 1000
var MoveLeft
var MoveRight
var MoveDown
var MoveJump
var Direction = -1.0 
var InputDirection
var SpeedDegradation = 5
var RespawnPosition
var Stock = 3
var CounterSteerBoost = 10
var LastShot = 0

var YBoundary = 1500
var LeftBoundary = -500
var RightBoundary = 2500

func IdentifyPlayer():
	if name == "Player1":
		MoveLeft = "LEFT"
		MoveRight = "RIGHT"
		MoveDown = "DOWN"
		MoveJump = "JUMP"
	elif name == "Player2":
		MoveLeft = "LEFT_2"
		MoveRight = "RIGHT_2"
		MoveDown = "DOWN_2"
		MoveJump = "JUMP_2"
	elif name == "Player3":
		MoveLeft = "LEFT_3"
		MoveRight = "RIGHT_3"
		MoveDown = "DOWN_3"
		MoveJump = "JUMP_3"
	elif name == "Player4":
		MoveLeft = "LEFT_4"
		MoveRight = "RIGHT_4"
		MoveDown = "DOWN_4"
		MoveJump = "JUMP_4"
	

func _ready() -> void:
	IdentifyPlayer()
	RespawnPosition = position
	add_to_group("players")

func _physics_process(delta: float) -> void:
	if position.y > YBoundary:
		Respawn()
		return
	
	#To prevent inconsistent death times after being shot off
	#the map, we let Yboundary kill the player, and keep
	#the player at the Xboundaries so they dont mess
	#up the cameras average position 
	if position.x > RightBoundary:
		position.x = RightBoundary
		return
	if position.x < LeftBoundary:
		position.x = LeftBoundary
		return
	
		#Fall Down Through Platform
	if Input.is_action_just_pressed(MoveDown):
		position.y += 1
	
	
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

	# Apply Acceeration if button pressed and player isnt above TS
	if abs(velocity.x) < TopSpeed:
		if InputDirection == 1:
			if (velocity.x + Acceleration) < TopSpeed:
				velocity.x += Acceleration
			else:
				velocity.x = 500
		elif InputDirection == -1:
			if (velocity.x - Acceleration) > -TopSpeed:
				velocity.x -= Acceleration
			else:
				velocity.x = -500
	
	#if player is above topspeed due to KNOCKBACK, let him slow down
	elif InputDirection == 1 and velocity.x < 0:
		velocity.x += CounterSteerBoost + ExtremeSpeedFriction
	elif InputDirection == -1 and velocity.x > 0:
		velocity.x -= CounterSteerBoost + ExtremeSpeedFriction
	
	if abs(velocity.x) > TopSpeed:
		velocity.x -= SpeedDegradation * Direction

	
	#Apply Friction or Air Resistance if nothing is pressed
	if is_on_floor():
		#if extreme speed, increase friction, else use normal
		var FrictionToUse = Friction
		
		if abs(velocity.x) > TopSpeed :
			FrictionToUse = ExtremeSpeedFriction
		else:
			FrictionToUse = Friction
		
		#To prevent pingponging, reset to zero
		if InputDirection == 0.0 and abs(velocity.x) < FrictionToUse:
			velocity.x = 0
		#ACTUALLY applying friction
		if InputDirection == 0.0 and velocity.x > 0.0:
			velocity.x -= FrictionToUse
		if InputDirection == 0.0 and velocity.x < 0.0:
			velocity.x += FrictionToUse
		
	else:
		#to prevent pingponging, reset to zero
		if InputDirection == 0.0 and abs(velocity.x) < AirResistance:
			velocity.x = 0
		#ACTUALLY applying air resistance
		elif InputDirection == 0.0 and velocity.x > 0.0:
			velocity.x -= AirResistance
		elif InputDirection == 0.0 and velocity.x < 0.0:
			velocity.x += AirResistance
	
	
	#Jumpy
	if Input.is_action_just_pressed(MoveJump) and CanJump == true:
		Jump()
	
	#Upwards and downwards gravity
	if velocity.y > 0 and !is_on_floor():
		velocity.y += DownGravity
	else:
		velocity.y += UpGravity
	
	#Turn Gun to direction
	HandNode.scale.x = Direction

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
	print("knockback of ", Knockback)
	velocity.x += Knockback * PushDirection

func DropGun(GunName: String):
	var DroppedGunScene = preload("res://Scenes/DroppedGun.tscn")
	var DroppedGun = DroppedGunScene.instantiate()
	
	DroppedGun.get_node("GunSprite").texture = load("res://Assets/OnlyGuns/" + GunName + ".png")
	DroppedGun.position = position
	
	get_tree().current_scene.add_child(DroppedGun)
	
	#Give Player Basic Glock
	var GlockScene = preload("res://Scenes/Glock29.tscn")
	var Glock = GlockScene.instantiate()
	WeaponHolderNode.add_child(Glock)

func Respawn() -> void:
	Stock -= 1
	if Stock > 0:
		position = RespawnPosition
		velocity = Vector2.ZERO
		CanJump = false
		CanDoubleJump = true
		get_child(2).get_child(0).get_child(0).queue_free()
		
		#Give Player Basic Glock
		var GlockScene = preload("res://Scenes/Glock29.tscn")
		var Glock = GlockScene.instantiate()
		WeaponHolderNode.add_child(Glock)
	
	else:
		remove_from_group("players")
	

func _on_coyote_timer_timeout() -> void:
	CanJump = false
