extends Node2D

var ShootButton

var BulletScene = preload("res://Scenes/bullet.tscn")
@onready var FireRateTimer = $FireRateTimer

#Gun Stats
var Recoil = 750.0
var FireRate = 0.3
var MagSize = -1 #-1 for infinite
var GunName
var CanShoot = true

#Bullet Stats
var BulletSpeed = 75
var BulletLifeTime = 10.0
var BulletKnockback = 1250.0
var BulletDirection = -1

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	IdentifyPlayerShoot()


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	#Find direction player is facing and make bullets shoot that way now instead yuh
	if get_parent().get_parent().get_parent().Direction != 0:
		BulletDirection = get_parent().get_parent().get_parent().Direction
	
	
	if Input.is_action_pressed(ShootButton) and CanShoot:
		Shoot()
		ApplyRecoil()

func IdentifyPlayerShoot():
	print(get_parent().get_parent().get_parent().name)
	if get_parent().get_parent().get_parent().name == "Player1":
		ShootButton = "SHOOT"
		print("Shoot button set as ", ShootButton, " FOR ", get_parent().get_parent().get_parent().name)
	elif get_parent().get_parent().get_parent().name == "Player2":
		ShootButton = "SHOOT_2"
		print("Shoot button set as ", ShootButton, " FOR ", get_parent().get_parent().get_parent().name)

func Shoot():
	if MagSize != -1: #Check if this gun has infinite ammo
		MagSize -= 1
	var Bullet = BulletScene.instantiate()
	
	Bullet.global_position = $Muzzle.global_position
	Bullet.Direction = BulletDirection
	Bullet.Speed = BulletSpeed
	Bullet.Lifetime = BulletLifeTime
	Bullet.Knockback = BulletKnockback
	get_tree().current_scene.add_child(Bullet)
	
	
	StartCooldown()

func ApplyRecoil():
	get_parent().get_parent().get_parent().velocity.x -= Recoil * get_parent().get_parent().get_parent().Direction


func StartCooldown():
	CanShoot = false
	FireRateTimer.start(FireRate)
	

func _on_fire_rate_timer_timeout() -> void:
	CanShoot = true
	
