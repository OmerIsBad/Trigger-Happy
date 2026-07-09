extends Node2D

var ShootButton

var RocketScene = preload("res://Scenes/Rocket.tscn")
@onready var FireRateTimer = $FireRateTimer
@onready var PlayerHand = get_parent().get_parent()



#Gun Stats
var Recoil = 1200.0
var FireRate = 1.75
var MagSize = 5 #-1 for infinite
var GunName = "RocketLauncher"
var CanShoot = true

#Rocket Stats
var RocketSpeed = 20
var RocketLifeTime = 30.0
var RocketKnockback = 0
var RocketDirection = -1

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	IdentifyPlayerShoot()
	


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	#Find direction player is facing and make bullets shoot that way now instead yuh
	if get_parent().get_parent().get_parent().Direction != 0:
		RocketDirection = get_parent().get_parent().get_parent().Direction
	
	
	if Input.is_action_pressed(ShootButton) and CanShoot:
		Shoot()
		if MagSize != 0:
			ApplyRecoil()

func IdentifyPlayerShoot():
	print(get_parent().get_parent().get_parent().name)
	if get_parent().get_parent().get_parent().name == "Player1":
		ShootButton = "SHOOT"
		print("Shoot button set as ", ShootButton, " FOR ", get_parent().get_parent().get_parent().name)
	elif get_parent().get_parent().get_parent().name == "Player2":
		ShootButton = "SHOOT_2"
		print("Shoot button set as ", ShootButton, " FOR ", get_parent().get_parent().get_parent().name)
	elif get_parent().get_parent().get_parent().name == "Player3":
		ShootButton = "SHOOT_3"
		print("Shoot button set as ", ShootButton, " FOR ", get_parent().get_parent().get_parent().name)
	elif get_parent().get_parent().get_parent().name == "Player4":
		ShootButton = "SHOOT_4"
		print("Shoot button set as ", ShootButton, " FOR ", get_parent().get_parent().get_parent().name)

func Shoot():
	if MagSize != -1: #Check if this gun has infinite ammo
		MagSize -= 1
		
	var Rocket = RocketScene.instantiate()
	
	Rocket.global_position = $Muzzle.global_position
	Rocket.Direction = RocketDirection
	Rocket.Speed = RocketSpeed
	Rocket.Lifetime = RocketLifeTime
	Rocket.Knockback = RocketKnockback
	get_tree().current_scene.add_child(Rocket)
	
	if MagSize == 0:
		DestroyGun()
	else:
		StartCooldown()

func ApplyRecoil():
	get_parent().get_parent().get_parent().velocity.x -= Recoil * get_parent().get_parent().get_parent().Direction
	
	var RestPosition = PlayerHand.position
	var KickPosition = RestPosition + Vector2(-15 * RocketDirection, 0)
	
	var RecoilTween = create_tween().set_trans(Tween.TRANS_EXPO).set_ease(Tween.EASE_OUT)
	RecoilTween.tween_property(PlayerHand, "position", KickPosition, 0.05)
	RecoilTween.tween_property(PlayerHand, "position", RestPosition, 0.1)

func DestroyGun():
	get_parent().get_parent().get_parent().DropGun(GunName)
	queue_free()

func StartCooldown():
	CanShoot = false
	FireRateTimer.start(FireRate)
	

func _on_fire_rate_timer_timeout() -> void:
	CanShoot = true
