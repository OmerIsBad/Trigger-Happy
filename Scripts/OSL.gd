extends Node2D
var Knockback = 5000
var PushDirection = 1
var Daddy
var Left
var Right
var Secondary
var AimVelocity = 0.0
var AimAcceleration = 80.0
var AimTopSpeed = 500.0
var AimFriction = 40.0
var Last = 0
var CurrentState
var BlinkSpeed = 0.025 
var IsVisible = true
var TimeyTimey = 0.0
var OscillationSpeed = 10
@onready var AnimatedSprite = $AnimatedSprite2D
@onready var AimingTimer = $AimingTimer
@onready var LaserTimer = $LaserTimer
@onready var SirenSFX = $SirenSFX
@onready var LockOnSFX = $LockOnSFX
@onready var LaserSFX = $LaserSFX
@onready var PsshSFX = $PsshSFX
@onready var BoomSFX = $BoomSFX

var Explosion = preload("res://Scenes/LaserExplosion.tscn")

func _ready() -> void:
	Daddy = get_parent()
	Daddy.add_to_group("PlayersThatEitherShotOrAreHitByTheLaserTypeShi")
	Left = Daddy.MoveLeft
	Right = Daddy.MoveRight
	Secondary = Daddy.Secondary
	AnimatedSprite.modulate = Color(0, 0, 0, 0)
	CurrentState = "Off"

func _process(delta: float) -> void:
	if Input.is_action_just_pressed(Secondary) and CurrentState == "Off":
		SirenSFX.play()
		CurrentState = "Aiming"
		AnimatedSprite.play("Aim")
	
	elif Input.is_action_just_pressed(Secondary) and CurrentState == "Aiming":
		SirenSFX.stop()
		LockOnSFX.play()
		CurrentState = "Warning"
		AnimatedSprite.modulate = Color.RED
		AimingTimer.start()
	
	if CurrentState == "Off":
		return
	
	if CurrentState == "Aiming":
		TimeyTimey += delta
		var Opacity = (sin(TimeyTimey * OscillationSpeed) + 1.0) / 2.0
		AnimatedSprite.modulate = Color(1, 1, 1, Opacity + 0.25)
		
		if Input.is_action_pressed(Left):
			if AimVelocity - AimAcceleration > -AimTopSpeed:
				AimVelocity -= AimAcceleration
			else:
				AimVelocity = -AimTopSpeed
		elif Input.is_action_pressed(Right):
			if AimVelocity + AimAcceleration < AimTopSpeed:
				AimVelocity += AimAcceleration
			else:
				AimVelocity = AimTopSpeed
		else:
			if abs(AimVelocity) < AimFriction:
				AimVelocity = 0
			elif AimVelocity > 0:
				AimVelocity -= AimFriction
			elif AimVelocity < 0:
				AimVelocity += AimFriction
		
		position.x += AimVelocity * delta
	
	elif CurrentState == "Warning":
		var Current = floor(AimingTimer.time_left * 10) / 10.0
		if Current != Last:
			IsVisible = !IsVisible
			AnimatedSprite.modulate = Color(1, 0, 0, 1) if IsVisible else Color(0, 0, 0, 0)
			Last = Current

func _on_aiming_timer_timeout() -> void:
	LockOnSFX.stop()
	LaserSFX.play()
	PsshSFX.play()
	BoomSFX.play()
	
	CurrentState = "Shooting"
	AnimatedSprite.modulate = Color(100.5,1,1,1)
	AnimatedSprite.play("Laser")
	LaserTimer.start()
	global.CameraShake(30,2)
	reparent(Daddy.get_parent())

func _on_area_2d_body_entered(body: Node2D) -> void:
	if CurrentState == "Shooting" and body.is_in_group("players") and !body.is_in_group("PlayersThatEitherShotOrAreHitByTheLaserTypeShi"):
		
		var Kaboom = Explosion.instantiate()
		Kaboom.global_position = body.global_position
		get_tree().current_scene.add_child(Kaboom)
		
		PushDirection = sign(body.global_position.x - global_position.x)
		if PushDirection == 0:
			PushDirection = 1
			
		body.ApplyKnockback(Knockback, PushDirection)
		body.velocity.y -= 1500
		body.add_to_group("PlayersThatEitherShotOrAreHitByTheLaserTypeShi")
	
	if CurrentState == "Shooting" and body.is_in_group("Turrets"):
		body.Shatter()
		body.queue_free()

func _on_laser_timer_timeout() -> void:
	Daddy.CanMove = true
	for Player in get_tree().get_nodes_in_group("PlayersThatEitherShotOrAreHitByTheLaserTypeShi"):
		Player.remove_from_group("PlayersThatEitherShotOrAreHitByTheLaserTypeShi")
	queue_free()
