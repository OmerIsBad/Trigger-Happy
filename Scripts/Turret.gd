extends CharacterBody2D

@onready var RightCast = $RightCast
@onready var LeftCast = $LeftCast
@onready var Sprite = $Sprite2D
@onready var LifeBar = $LifeBar
@onready var LifeTimer = $LifeTime
@onready var Marker = $Sprite2D/Marker2D
@onready var FireRateTimer = $FireRateTimer
@onready var GunShotSFX = $GunShotSFX
#Set Up Sfx
@onready var ClangSFX: AudioStreamPlayer2D = $ClangSFX
@onready var CreakSFX: AudioStreamPlayer2D = $CreakSFX
@onready var LoadSFX: AudioStreamPlayer2D = $LoadSFX
#Break SFX
@onready var ScrapeSFX: AudioStreamPlayer2D = $ScrapeSFX
@onready var SnapSFX: AudioStreamPlayer2D = $SnapSFX
@onready var ExplodeSFX: AudioStreamPlayer2D = $ExplodeSFX


#Bullet Stats
var BulletSpeed = 85
var BulletLifeTime = 10.0
var BulletKnockback = 650.0
var BulletDirection = -1

var BulletScene = preload("res://Scenes/bullet.tscn")
var TurretPiece = preload("res://Scenes/TurretPiece.tscn")

var TurretOwner

var Direction = 1
var CanShoot = true
var MaxTime
# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	ClangSFX.play()
	CreakSFX.play()
	LoadSFX.play()
	print("My Owner is ", TurretOwner)
	MaxTime = LifeTimer.wait_time
	add_to_group("Turrets")
	
	var FillStyle = (LifeBar.get_theme_stylebox("fill") as StyleBoxTexture).duplicate()
	
	if TurretOwner == "Player1":
		FillStyle.modulate_color = Color("b51111")
		LeftCast.set_collision_mask_value(2, false)
		RightCast.set_collision_mask_value(2, false)
	elif TurretOwner == "Player2":
		FillStyle.modulate_color = Color("115bb5")
		LeftCast.set_collision_mask_value(3, false)
		RightCast.set_collision_mask_value(3, false)
	elif TurretOwner == "Player3":
		FillStyle.modulate_color = Color("33af22")
		LeftCast.set_collision_mask_value(4, false)
		RightCast.set_collision_mask_value(4, false)
	elif TurretOwner == "Player4":
		FillStyle.modulate_color = Color("ffdb00")
		LeftCast.set_collision_mask_value(5, false)
		RightCast.set_collision_mask_value(5, false)
	
	LifeBar.add_theme_stylebox_override("fill", FillStyle)

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	LifeBar.value = (LifeTimer.time_left / MaxTime) * 100

	var PlayerLeftPosition = Vector2(99999, 99999)
	var PlayerRightPosition = Vector2(99999, 99999)
	
	var FireNow = false
	if LeftCast.is_colliding():
		FireNow = true
		PlayerLeftPosition = LeftCast.get_collider().global_position
	if RightCast.is_colliding():
		FireNow = true
		PlayerRightPosition = RightCast.get_collider().global_position
	
	var Target
	if abs(global_position - PlayerLeftPosition) < abs(global_position - PlayerRightPosition) and Direction != -1:
		Target = PlayerLeftPosition
		Direction = -1
	elif abs(global_position - PlayerLeftPosition) > abs(global_position - PlayerRightPosition) and Direction != 1:
		Target = PlayerRightPosition
		Direction = 1
		
	Sprite.scale.x = Direction*2
	
	if FireNow and CanShoot:
		CanShoot = false
		FireRateTimer.start()
		var Bullet = BulletScene.instantiate()
		
		Bullet.global_position = Marker.global_position
		Bullet.Direction = Direction
		Bullet.Speed = BulletSpeed
		Bullet.Lifetime = BulletLifeTime
		Bullet.Knockback = BulletKnockback
		Bullet.ShotByGun = "Turret"
		
		get_tree().current_scene.add_child(Bullet)
		
		var PitchMin = 0.8
		var PitchMax = 1.2
		
		GunShotSFX.pitch_scale = randf_range(PitchMin, PitchMax)
		GunShotSFX.play()
	
func Shatter() -> void:
	var Positions = ["TL", "TR", "BL", "BR"]
	for PieceIndexValue in Positions:
		var Piece = TurretPiece.instantiate()
		Piece.PieceIndex = PieceIndexValue
		Piece.global_position = global_position
		get_tree().current_scene.add_child(Piece)

func _on_life_time_timeout() -> void:
	GunShotSFX.reparent(get_tree().current_scene)
	GunShotSFX.finished.connect(GunShotSFX.queue_free)
	
	SnapSFX.play()
	SnapSFX.reparent(get_tree().current_scene)
	SnapSFX.finished.connect(SnapSFX.queue_free)
	
	ScrapeSFX.play()
	ScrapeSFX.reparent(get_tree().current_scene)
	ScrapeSFX.finished.connect(ScrapeSFX.queue_free)
	
	ExplodeSFX.play()
	ExplodeSFX.reparent(get_tree().current_scene)
	ExplodeSFX.finished.connect(ExplodeSFX.queue_free)
	
	Shatter()
	queue_free()

func _on_fire_rate_timer_timeout() -> void:
	CanShoot = true
