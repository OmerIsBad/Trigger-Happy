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

func _ready() -> void:
	Daddy = get_parent()
	Daddy.add_to_group("PlayersThatEitherShotOrAreHitByTheLaserTypeShi")
	Left = Daddy.MoveLeft
	Right = Daddy.MoveRight
	Secondary = Daddy.Secondary
	AnimatedSprite.play("Aim")
	CurrentState = "Aiming"

func _process(delta: float) -> void:
	if Input.is_action_just_pressed(Secondary) and CurrentState == "Aiming":
		CurrentState = "Warning"
		AnimatedSprite.modulate = Color.RED
		AimingTimer.start()
	
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
	CurrentState = "Shooting"
	AnimatedSprite.modulate = Color(1,1,1,1)
	AnimatedSprite.play("Laser")
	LaserTimer.start()
	global.CameraShake(75,69420)
	reparent(Daddy.get_parent())


func _on_area_2d_body_entered(body: Node2D) -> void:
	if CurrentState == "Shooting" and body.is_in_group("players") and !body.is_in_group("PlayersThatEitherShotOrAreHitByTheLaserTypeShi"):
		
		PushDirection = sign(body.global_position.x - global_position.x)
		if PushDirection == 0:
			PushDirection = 1
			
		body.ApplyKnockback(Knockback, PushDirection)
		body.velocity.y -= 1500
		body.add_to_group("PlayersThatEitherShotOrAreHitByTheLaserTypeShi")



func _on_laser_timer_timeout() -> void:
	Daddy.CanMove = true
	queue_free()
