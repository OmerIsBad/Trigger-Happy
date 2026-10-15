extends Node2D

var ShootButton

var MissileScene = preload("res://Scenes/Missile.tscn")
@onready var FireRateTimer = $FireRateTimer
@onready var PlayerHand = get_parent().get_parent()
@onready var GunShotSFX = $GunShotSFX



#Gun Stats
var Recoil = 1200.0
var FireRate = 2.00
var MagSize = 3 #-1 for infinite
var GunName = "MissileLauncher"
var GunType = "mLAUNCHER"
var CanShoot = true

#Rocket Stats
var MissileSpeed = 550
var MissileLifeTime = 30.0
var MissileKnockback = 0
var MissileDirection = -1
var MissileShotBy

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	IdentifyPlayerShoot()
	MissileShotBy = get_parent().get_parent().get_parent().name


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	#Find direction player is facing and make bullets shoot that way now instead yuh
	if get_parent().get_parent().get_parent().Direction != 0:
		MissileDirection = get_parent().get_parent().get_parent().Direction
	
	
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
		
	var Missile = MissileScene.instantiate()
	
	Missile.global_position = $Muzzle.global_position
	Missile.Direction = MissileDirection
	Missile.Speed = MissileSpeed
	Missile.Lifetime = MissileLifeTime
	Missile.Knockback = MissileKnockback
	Missile.ShotBy = MissileShotBy
	Missile.ShotByGun = GunName
	get_tree().current_scene.add_child(Missile)
	
	GunShotSFX.play(0.03)
	
	if MagSize == 0:
		DestroyGun()
	else:
		StartCooldown()

func ApplyRecoil():
	get_parent().get_parent().get_parent().velocity.x -= Recoil * get_parent().get_parent().get_parent().Direction
	
	var RestPosition = PlayerHand.position
	var KickPosition = RestPosition + Vector2(-15 * MissileDirection, 0)
	
	var RecoilTween = create_tween().set_trans(Tween.TRANS_EXPO).set_ease(Tween.EASE_OUT)
	RecoilTween.tween_property(PlayerHand, "position", KickPosition, 0.05)
	RecoilTween.tween_property(PlayerHand, "position", RestPosition, 0.1)

func DestroyGun():
	GunShotSFX.reparent(get_tree().current_scene)
	GunShotSFX.finished.connect(GunShotSFX.queue_free)
	get_parent().get_parent().get_parent().DropGun(GunName)
	queue_free()

func StartCooldown():
	CanShoot = false
	FireRateTimer.start(FireRate)
	

func _on_fire_rate_timer_timeout() -> void:
	CanShoot = true
