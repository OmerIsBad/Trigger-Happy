extends CharacterBody2D

@onready var HandNode = $Hand
@onready var WeaponHolderNode = $Hand/WeaponHolder
@onready var CoyoteTimerNode = $CoyoteTimer
@onready var AnimatedSprite = $AnimatedSprite2D
@onready var PunchTimer = $PunchCoolDown
@onready var ItemInstructor = $ItemInstructor
@onready var LandSFX = $LandSFX

var SpawnShieldScene = preload("res://Scenes/SpawnShield.tscn")
var PunchingScene = preload("res://Scenes/Punch.tscn")

var CoyoteTime = 0.15
var CanJump = true

var CanDoubleJump = false
var Acceleration = 40.0
var NormalAccel = Acceleration
var TopSpeed = 500.0
var NormalTopSpeed = TopSpeed
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
var Secondary
var Direction = -1.0 
var InputDirection
var SpeedDegradation = 5
var RespawnPosition
var Stock = 3
var CounterSteerBoost = 10
var LastShot = 0
var ShieldMaskOverride = false
var CanMove = true
var IsSpeedBoosted = false
var IsDashing = false
var DashSpeed = 3732.0
var DashDuration = 0.1
var DashTimer = 0.0
var DashDirectionVector = Vector2.ZERO
var DashGhostShader = preload("res://Shaders/TrailTint.gdshader")
var DashGhostTimer = 0.0
var DashGhostInterval = 0.001
var WasOnLand = false

var FirstPress = 0
var HeldDown = false
var HoldTime = 500
var IsAPunch
var CanPunch = true
var NodeOverridePunch = false

var YBoundary = 1500
var LeftBoundary = -500
var RightBoundary = 2500

func IdentifyPlayer():
	if name == "Player1":
		MoveLeft = "LEFT"
		MoveRight = "RIGHT"
		MoveDown = "DOWN"
		MoveJump = "JUMP"
		Secondary = "SECONDARY"
	elif name == "Player2":
		MoveLeft = "LEFT_2"
		MoveRight = "RIGHT_2"
		MoveDown = "DOWN_2"
		MoveJump = "JUMP_2"
		Secondary = "SECONDARY_2"
	elif name == "Player3":
		MoveLeft = "LEFT_3"
		MoveRight = "RIGHT_3"
		MoveDown = "DOWN_3"
		MoveJump = "JUMP_3"
		Secondary = "SECONDARY_3"
	elif name == "Player4":
		MoveLeft = "LEFT_4"
		MoveRight = "RIGHT_4"
		MoveDown = "DOWN_4"
		MoveJump = "JUMP_4"
		Secondary = "SECONDARY_4"

var LastUsedEvent = {}  

func _input(event: InputEvent) -> void:
	for ActionName in InputMap.get_actions():
		if event.is_action(ActionName) and (event.is_pressed() or event is InputEventJoypadMotion):
			LastUsedEvent[ActionName] = event

func GetCleanEventText(Event: InputEvent) -> String:
	if Event is InputEventKey:
		var Keycode = Event.physical_keycode if Event.physical_keycode != 0 else Event.keycode
		
		match Keycode:
			KEY_KP_0: return "0"
			KEY_KP_1: return "1"
			KEY_KP_2: return "2"
			KEY_KP_3: return "3"
			KEY_KP_4: return "4"
			KEY_KP_5: return "5"
			KEY_KP_6: return "6"
			KEY_KP_7: return "7"
			KEY_KP_8: return "8"
			KEY_KP_9: return "9"
			KEY_KP_PERIOD: return "."
			KEY_KP_ADD: return "+"
			KEY_KP_SUBTRACT: return "-"
			KEY_KP_MULTIPLY: return "*"
			KEY_KP_DIVIDE: return "/"
			KEY_KP_ENTER: return "Enter"
			_: return OS.get_keycode_string(Keycode)
	
	elif Event is InputEventJoypadButton:
		return "Button " + str(Event.button_index)
	elif Event is InputEventJoypadMotion:
		return "Axis " + str(Event.axis)
	elif Event is InputEventMouseButton:
		return "Mouse " + str(Event.button_index)
	
	return Event.as_text()

var KeypadNameOverrides = {
	"KP Period": ".",
	"KP Add": "+",
	"KP Subtract": "-",
	"KP Multiply": "*",
	"KP Divide": "/",
	"KP Enter": "Enter",
	"KP 0": "0", "KP 1": "1", "KP 2": "2", "KP 3": "3", "KP 4": "4",
	"KP 5": "5", "KP 6": "6", "KP 7": "7", "KP 8": "8", "KP 9": "9",
}

func CleanUpKeypadName(RawName: String) -> String:
	if KeypadNameOverrides.has(RawName):
		return KeypadNameOverrides[RawName]
	return RawName

func GetMappedInput(ActionName: String) -> String:
	var Event
	if LastUsedEvent.has(ActionName):
		Event = LastUsedEvent[ActionName]
	else:
		var Events = InputMap.action_get_events(ActionName)
		if Events.size() > 0:
			Event = Events[0]
		else:
			return "Unbound"
	
	var CleanText = GetCleanEventText(Event)
	return CleanUpKeypadName(CleanText)

func _ready() -> void:
	global.NormalAcc = Acceleration
	global.NormalTopSpeed = TopSpeed
	
	IdentifyPlayer()
	RespawnPosition = position
	add_to_group("players")
	
	if name == "Player1":
		ItemInstructor.add_theme_color_override("font_outline_color", Color("b51111"))
	if name == "Player2":
		ItemInstructor.add_theme_color_override("font_outline_color", Color("115bb5"))
	if name == "Player3":
		ItemInstructor.add_theme_color_override("font_outline_color", Color("33af22"))
	if name == "Player4":
		ItemInstructor.add_theme_color_override("font_outline_color", Color("ffdb00"))




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
		velocity.x = 0
		return
	if position.x < LeftBoundary:
		position.x = LeftBoundary
		velocity.x = 0
		return
	
	#Item Instructor:
	#Mine:
	if has_node("MinePlacerItem"):
		ItemInstructor.text = "Press [" + str(GetMappedInput(Secondary)) + "] To Place"
	elif has_node("ShieldManager"):
		ItemInstructor.text = "Hold [" + str(GetMappedInput(Secondary)) + "] To Use"
	elif has_node("PortalManager"):
		ItemInstructor.text = "Press [" + str(GetMappedInput(Secondary)) + "] To Place"
	elif has_node("DuckBombManager"):
		ItemInstructor.text = "Press [" + str(GetMappedInput(Secondary)) + "] To Place"
	elif has_node("JetPack"):
		ItemInstructor.text = "Press [" + str(GetMappedInput(Secondary)) + "] To Fly"
	elif has_node("GrenadeManager"):
		ItemInstructor.text = "Hold [" + str(GetMappedInput(Secondary)) + "] To Throw"
	elif has_node("TurretManager"):
		ItemInstructor.text = "Press [" + str(GetMappedInput(Secondary)) + "] To Place"
	elif has_node("DashManager"):
		ItemInstructor.text = "Press [" + str(GetMappedInput(Secondary)) + "] To Dash\n " + str(get_node("DashManager").DashesRemaining) + "/5"
	elif has_node("OSL"):
		if get_node("OSL").CurrentState == "Off":
			ItemInstructor.text = "Press [" + str(GetMappedInput(Secondary)) + "] To Order \n Orbital Strike Laser"
		elif get_node("OSL").CurrentState == "Aiming":
			ItemInstructor.text = "Press [" + str(GetMappedInput(Secondary)) + "] To Fire"
			CanMove = false
	else:
		ItemInstructor.text = ""
		CanMove = true
		
	if has_node("ShieldManager"):
		if get_node("ShieldManager").has_node("Shield"):
			set_collision_mask_value(7, false)
		elif !ShieldMaskOverride:
			set_collision_mask_value(7, true)

	if WasOnLand == false and is_on_floor() == true:
		var PitchMin = 0.4
		var PitchMax = 0.5
		
		LandSFX.pitch_scale = randf_range(PitchMin, PitchMax)
		LandSFX.play()
		
	if is_on_floor():
		WasOnLand = true
	else:
		WasOnLand = false
	
	if Input.is_action_just_pressed(Secondary) and !NodeOverridePunch:
		Punch()
	
	if has_node("SpeedManager") and !IsSpeedBoosted:
		IsSpeedBoosted = true
		TopSpeed = NormalTopSpeed * get_node("SpeedManager").BoostedSpeed
		Acceleration = NormalAccel * get_node("SpeedManager").BoostedAccel
	if not has_node("SpeedManager") and IsSpeedBoosted:
		IsSpeedBoosted = false
		TopSpeed = NormalTopSpeed
		Acceleration = NormalAccel
	
	if has_node("MinePlacerItem") or has_node("ShieldManager") or has_node("PortalManager") or has_node("OSL") or has_node("DuckBombManager") or has_node("JetPack") or has_node("GrenadeManager") or has_node("TurretManager") or has_node("DashManager"):
		NodeOverridePunch = true
	else:
		NodeOverridePunch = false
	
	if Input.is_action_just_pressed("ui_accept") and name == "Player1" and !has_node("OSL"):
		var poop = preload("res://Scenes/OSL.tscn").instantiate()
		add_child(poop)

	if IsDashing:
		DashTimer -= delta
		velocity = DashDirectionVector * DashSpeed
		
		DashGhostTimer += delta
		if DashGhostTimer >= DashGhostInterval:
			DashGhostTimer = 0.0
			SpawnDashGhost()
		
		if DashTimer <= 0.0:
			EndDash()
	elif CanMove:
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
					velocity.x = TopSpeed
			elif InputDirection == -1:
				if (velocity.x - Acceleration) > -TopSpeed:
					velocity.x -= Acceleration
				else:
					velocity.x = -TopSpeed
		
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
	
	else:
		velocity = Vector2(0,0)
		InputDirection = 0
		Direction = 0
		if has_node("SpawnShield") == false:
			var Shield = SpawnShieldScene.instantiate()
			add_child(Shield)
		

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

func Punch():
	if CanPunch:
		var Punch = PunchingScene.instantiate()
		#Punch.global_position = global_position
		Punch.Puncher = name
		Punch.PunchDirection = Direction
		
		add_child(Punch)
		
		CanPunch = false
		PunchTimer.start()

func Jump():
	velocity.y = -JumpForce
	CanJump = false

func StartDash() -> void:
	if IsDashing or !CanMove:
		return
	
	var DashDir = Vector2.ZERO
	if Input.is_action_pressed(MoveLeft):
		DashDir.x -= 1
	if Input.is_action_pressed(MoveRight):
		DashDir.x += 1
	if Input.is_action_pressed(MoveDown):
		DashDir.y += 1
	if Input.is_action_pressed(MoveJump):
		DashDir.y -= 1
	
	if DashDir == Vector2.ZERO:
		DashDir.x = Direction
	
	DashDirectionVector = DashDir.normalized()
	IsDashing = true
	DashTimer = DashDuration
	add_to_group("DashInvincible")

func EndDash() -> void:
	IsDashing = false
	velocity = DashDirectionVector * TopSpeed
	remove_from_group("DashInvincible")

func SpawnDashGhost() -> void:
	var Ghost = Sprite2D.new()
	Ghost.texture = AnimatedSprite.sprite_frames.get_frame_texture(AnimatedSprite.animation, AnimatedSprite.frame)
	Ghost.global_position = AnimatedSprite.global_position
	Ghost.global_rotation = AnimatedSprite.global_rotation
	Ghost.scale = AnimatedSprite.scale * scale
	Ghost.flip_h = AnimatedSprite.flip_h
	Ghost.z_index = AnimatedSprite.z_index - 1
	
	var GhostMat = ShaderMaterial.new()
	GhostMat.shader = DashGhostShader
	GhostMat.set_shader_parameter("opacity", 0.5)
	GhostMat.set_shader_parameter("r", 0.1)
	GhostMat.set_shader_parameter("g", 0.4)
	GhostMat.set_shader_parameter("b", 1.0)
	GhostMat.set_shader_parameter("mix_color", 0.85)
	Ghost.material = GhostMat
	
	get_tree().current_scene.add_child(Ghost)
	
	var FadeTween = Ghost.create_tween()
	FadeTween.tween_property(Ghost, "modulate:a", 0.0, 0.3)
	FadeTween.tween_callback(Ghost.queue_free)

func ApplyKnockback(Knockback, PushDirection):
	if !has_node("SpawnShield"):
		if IsDashing:
			return
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

func DropItem(ItemName: String):
	var ItemSprite
	if ItemName == "Shield":
		ItemSprite = preload("res://Assets/Shield.png")
	
	var DroppedItemScene = preload("res://Scenes/DroppedGun.tscn")
	var DroppedItem = DroppedItemScene.instantiate()
	
	DroppedItem.get_node("GunSprite").texture = ItemSprite
	DroppedItem.position = position
	
	get_tree().current_scene.add_child(DroppedItem)
	

func Respawn() -> void:
	Stock -= 1
	if Stock > 0:
		var SpawnShield = SpawnShieldScene.instantiate()
		add_child(SpawnShield)
		position = RespawnPosition
		velocity = Vector2.ZERO
		CanJump = false
		CanDoubleJump = true
		get_child(2).get_child(0).get_child(0).queue_free()
		
		var ItemNodeNames = ["DashManager", "DuckBombManager", "GrenadeManager", "JetPack", "MinePlacerItem", "PortalManager", "TurretManager", "SpeedManager", "ShieldManager", "OSL"]
		for ItemNodeName in ItemNodeNames:
			if has_node(ItemNodeName):
				get_node(ItemNodeName).queue_free()
		
		#Give Player Basic Glock
		var GlockScene = preload("res://Scenes/Glock29.tscn")
		var Glock = GlockScene.instantiate()
		WeaponHolderNode.add_child(Glock)
	
	else:
		remove_from_group("players")
	

func _on_coyote_timer_timeout() -> void:
	CanJump = false


func _on_punch_cool_down_timeout() -> void:
	CanPunch = true
